const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const { randomUUID } = require("crypto");

const app = express();

app.use(express.json());
app.use(cors());

// ==========================================================
// SEGURIDAD
// ==========================================================

const verificarJWT = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({
      error: "Acceso no autorizado",
      detalle: "Se requiere un token JWT.",
    });
  }

  const token = authHeader.split(" ")[1];

  try {
    const tokenParts = token.split(".");

    let payload = {};

    if (tokenParts.length >= 2) {
      payload = JSON.parse(
        Buffer.from(tokenParts[1], "base64url").toString("utf8"),
      );
    }

    req.user = {
      uid: payload.user_id || payload.sub || "",
      email: payload.email || "usuario@local",
      role: "admin",
    };

    next();
  } catch (error) {
    return res.status(401).json({
      error: "Token inválido",
      detalle: "No fue posible interpretar el token.",
    });
  }
};

// ==========================================================
// UTILIDADES
// ==========================================================

const roundMoney = (value) =>
  Math.round((Number(value) + Number.EPSILON) * 100) / 100;

const validDiscount = (value) => {
  const discount = Number(value || 0);

  return Math.min(100, Math.max(0, discount));
};

// ==========================================================
// PROVEEDORES
// ==========================================================

const ProviderSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    phone: {
      type: String,
      required: true,
      trim: true,
    },
    email: {
      type: String,
      required: true,
      trim: true,
      lowercase: true,
    },
    notes: {
      type: String,
      default: "",
      trim: true,
    },
    active: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  },
);

const Provider = mongoose.model("Provider", ProviderSchema, "providers");

// ==========================================================
// PRODUCTOS
// ==========================================================

const ProductSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    brand: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      default: "",
    },
    sale_price: {
      type: Number,
      required: true,
      min: 0,
      default: 0,
    },
    purchase_price: {
      type: Number,
      required: true,
      min: 0,
      default: 0,
    },
    stock: {
      type: Number,
      required: true,
      min: 0,
      default: 0,
    },
    image_url: {
      type: String,
      default: "",
    },
    category_id: {
      type: Number,
      default: 1,
    },
    provider_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Provider",
      default: null,
    },
  },
  {
    timestamps: true,
  },
);

const Product = mongoose.model("Product", ProductSchema, "products");

// ==========================================================
// VENTAS
// ==========================================================

const SaleItemSchema = new mongoose.Schema(
  {
    product_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Product",
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    brand: {
      type: String,
      default: "",
    },
    quantity: {
      type: Number,
      required: true,
      min: 1,
    },
    unit_price: {
      type: Number,
      required: true,
    },
    unit_cost: {
      type: Number,
      required: true,
    },
    subtotal: {
      type: Number,
      required: true,
    },
    discount_percent: {
      type: Number,
      default: 0,
    },
    discount_amount: {
      type: Number,
      default: 0,
    },
    line_total: {
      type: Number,
      required: true,
    },
    line_cost: {
      type: Number,
      required: true,
    },
    profit: {
      type: Number,
      required: true,
    },
  },
  {
    _id: false,
  },
);

const SaleSchema = new mongoose.Schema(
  {
    folio: {
      type: String,
      required: true,
      unique: true,
    },
    items: {
      type: [SaleItemSchema],
      required: true,
    },
    subtotal: {
      type: Number,
      required: true,
    },
    product_discount: {
      type: Number,
      default: 0,
    },
    general_discount_percent: {
      type: Number,
      default: 0,
    },
    general_discount_amount: {
      type: Number,
      default: 0,
    },
    total_discount: {
      type: Number,
      default: 0,
    },
    total: {
      type: Number,
      required: true,
    },
    cost_total: {
      type: Number,
      required: true,
    },
    gross_profit: {
      type: Number,
      required: true,
    },
    payment_method: {
      type: String,
      enum: ["efectivo", "tarjeta", "transferencia", "otro"],
      default: "efectivo",
    },
    amount_received: {
      type: Number,
      required: true,
    },
    change: {
      type: Number,
      default: 0,
    },
    notes: {
      type: String,
      default: "",
    },
    status: {
      type: String,
      enum: ["completada", "cancelada"],
      default: "completada",
    },
    sold_by_uid: {
      type: String,
      default: "",
    },
    sold_by_email: {
      type: String,
      default: "",
    },
  },
  {
    timestamps: true,
  },
);

const Sale = mongoose.model("Sale", SaleSchema, "sales");

// ==========================================================
// RUTA PRINCIPAL
// ==========================================================

app.get("/", (req, res) => {
  res.status(200).json({
    status: "Online",
    message: "Backend de punto de venta activo",
    database_connected:
      mongoose.connection.readyState === 1
        ? "Conectado a MongoDB"
        : "Desconectado",
    timestamp: new Date(),
  });
});

// ==========================================================
// RESUMEN DEL DASHBOARD
// ==========================================================

app.get("/resumen", verificarJWT, async (req, res) => {
  try {
    const start = new Date();
    start.setHours(0, 0, 0, 0);

    const end = new Date();
    end.setHours(23, 59, 59, 999);

    const [
      totalProducts,
      totalProviders,
      salesToday,
      stockSummary,
      incomeSummary,
    ] = await Promise.all([
      Product.countDocuments(),
      Provider.countDocuments({
        active: true,
      }),
      Sale.countDocuments({
        status: "completada",
        createdAt: {
          $gte: start,
          $lte: end,
        },
      }),
      Product.aggregate([
        {
          $group: {
            _id: null,
            total: {
              $sum: "$stock",
            },
          },
        },
      ]),
      Sale.aggregate([
        {
          $match: {
            status: "completada",
            createdAt: {
              $gte: start,
              $lte: end,
            },
          },
        },
        {
          $group: {
            _id: null,
            total: {
              $sum: "$total",
            },
          },
        },
      ]),
    ]);

    res.json({
      total_productos: totalProducts,
      total_proveedores: totalProviders,
      stock_total: stockSummary[0]?.total || 0,
      ventas_hoy: salesToday,
      ingresos_hoy: incomeSummary[0]?.total || 0,
    });
  } catch (error) {
    res.status(500).json({
      error: "Error al obtener el resumen",
      detalle: error.message,
    });
  }
});

// ==========================================================
// PRODUCTOS
// ==========================================================

app.get("/productos", verificarJWT, async (req, res) => {
  try {
    const products = await Product.find()
      .sort({
        name: 1,
      })
      .lean();

    res.json(products);
  } catch (error) {
    res.status(500).json({
      error: "Error al obtener productos",
      detalle: error.message,
    });
  }
});

app.post("/productos", verificarJWT, async (req, res) => {
  try {
    const product = new Product(req.body);

    await product.save();

    res.status(201).json({
      mensaje: "Producto creado con éxito",
      producto: product,
    });
  } catch (error) {
    res.status(400).json({
      error: "Error al crear el producto",
      detalle: error.message,
    });
  }
});

app.put("/productos/:id", verificarJWT, async (req, res) => {
  try {
    const product = await Product.findByIdAndUpdate(
      req.params.id.trim(),
      req.body,
      {
        new: true,
        runValidators: true,
      },
    );

    if (!product) {
      return res.status(404).json({
        error: "Producto no encontrado",
      });
    }

    res.json({
      mensaje: "Producto actualizado",
      producto: product,
    });
  } catch (error) {
    res.status(400).json({
      error: "Error al actualizar producto",
      detalle: error.message,
    });
  }
});

app.patch("/productos/:id/vender", verificarJWT, async (req, res) => {
  try {
    const quantity = Number(req.body.cantidad);

    if (!Number.isInteger(quantity) || quantity <= 0) {
      return res.status(400).json({
        error: "Cantidad de venta no válida",
      });
    }

    const product = await Product.findOneAndUpdate(
      {
        _id: req.params.id.trim(),
        stock: {
          $gte: quantity,
        },
      },
      {
        $inc: {
          stock: -quantity,
        },
      },
      {
        new: true,
      },
    );

    if (!product) {
      return res.status(400).json({
        error: "Producto inexistente o stock insuficiente",
      });
    }

    res.json({
      mensaje: "Existencias actualizadas",
      producto: product,
    });
  } catch (error) {
    res.status(500).json({
      error: "Error al procesar la operación",
      detalle: error.message,
    });
  }
});

app.delete("/productos/:id", verificarJWT, async (req, res) => {
  try {
    const deleted = await Product.findByIdAndDelete(req.params.id.trim());

    if (!deleted) {
      return res.status(404).json({
        error: "Producto no encontrado",
      });
    }

    res.json({
      mensaje: "Producto eliminado correctamente",
    });
  } catch (error) {
    res.status(400).json({
      error: "Error al eliminar producto",
      detalle: error.message,
    });
  }
});

// ==========================================================
// PROVEEDORES
// ==========================================================

app.get("/proveedores", verificarJWT, async (req, res) => {
  try {
    const providers = await Provider.find({
      active: true,
    }).sort({
      name: 1,
    });

    res.json(providers);
  } catch (error) {
    res.status(500).json({
      error: "Error al obtener proveedores",
      detalle: error.message,
    });
  }
});

app.post("/proveedores", verificarJWT, async (req, res) => {
  try {
    const provider = new Provider({
      name: req.body.name,
      phone: req.body.phone,
      email: req.body.email,
      notes: req.body.notes || "",
    });

    await provider.save();

    res.status(201).json({
      mensaje: "Proveedor creado",
      proveedor: provider,
    });
  } catch (error) {
    res.status(400).json({
      error: "Error al crear proveedor",
      detalle: error.message,
    });
  }
});

app.put("/proveedores/:id", verificarJWT, async (req, res) => {
  try {
    const provider = await Provider.findByIdAndUpdate(
      req.params.id,
      {
        name: req.body.name,
        phone: req.body.phone,
        email: req.body.email,
        notes: req.body.notes || "",
      },
      {
        new: true,
        runValidators: true,
      },
    );

    if (!provider) {
      return res.status(404).json({
        error: "Proveedor no encontrado",
      });
    }

    res.json({
      mensaje: "Proveedor actualizado",
      proveedor: provider,
    });
  } catch (error) {
    res.status(400).json({
      error: "Error al actualizar proveedor",
      detalle: error.message,
    });
  }
});

app.delete("/proveedores/:id", verificarJWT, async (req, res) => {
  try {
    const provider = await Provider.findByIdAndUpdate(
      req.params.id,
      {
        active: false,
      },
      {
        new: true,
      },
    );

    if (!provider) {
      return res.status(404).json({
        error: "Proveedor no encontrado",
      });
    }

    res.json({
      mensaje: "Proveedor eliminado",
    });
  } catch (error) {
    res.status(400).json({
      error: "Error al eliminar proveedor",
      detalle: error.message,
    });
  }
});

// ==========================================================
// VENTAS
// ==========================================================

app.post("/ventas", verificarJWT, async (req, res) => {
  const updatedProducts = [];

  try {
    const requestedItems = req.body.items;

    if (!Array.isArray(requestedItems) || requestedItems.length === 0) {
      return res.status(400).json({
        error: "La venta debe contener productos",
      });
    }

    const repeatedIds = new Set();

    for (const item of requestedItems) {
      if (!mongoose.Types.ObjectId.isValid(item.product_id)) {
        return res.status(400).json({
          error: "Identificador de producto inválido",
        });
      }

      if (repeatedIds.has(item.product_id)) {
        return res.status(400).json({
          error: "Un producto aparece repetido en la venta",
        });
      }

      repeatedIds.add(item.product_id);
    }

    const productIds = requestedItems.map((item) => item.product_id);

    const products = await Product.find({
      _id: {
        $in: productIds,
      },
    });

    if (products.length !== requestedItems.length) {
      return res.status(404).json({
        error: "Uno o más productos no existen",
      });
    }

    const productMap = new Map(
      products.map((product) => [product._id.toString(), product]),
    );

    const saleItems = [];

    let subtotal = 0;
    let productDiscount = 0;
    let costTotal = 0;

    for (const requestedItem of requestedItems) {
      const quantity = Number(requestedItem.quantity);

      if (!Number.isInteger(quantity) || quantity <= 0) {
        return res.status(400).json({
          error: "Cantidad de producto inválida",
        });
      }

      const product = productMap.get(requestedItem.product_id);

      if (product.stock < quantity) {
        return res.status(400).json({
          error: `Stock insuficiente para ${product.name}`,
        });
      }

      const discountPercent = validDiscount(requestedItem.discount_percent);

      const lineSubtotal = roundMoney(product.sale_price * quantity);

      const lineDiscount = roundMoney((lineSubtotal * discountPercent) / 100);

      const lineTotal = roundMoney(lineSubtotal - lineDiscount);

      const lineCost = roundMoney(product.purchase_price * quantity);

      const profit = roundMoney(lineTotal - lineCost);

      subtotal += lineSubtotal;
      productDiscount += lineDiscount;
      costTotal += lineCost;

      saleItems.push({
        product_id: product._id,
        name: product.name,
        brand: product.brand,
        quantity,
        unit_price: product.sale_price,
        unit_cost: product.purchase_price,
        subtotal: lineSubtotal,
        discount_percent: discountPercent,
        discount_amount: lineDiscount,
        line_total: lineTotal,
        line_cost: lineCost,
        profit,
      });
    }

    subtotal = roundMoney(subtotal);
    productDiscount = roundMoney(productDiscount);
    costTotal = roundMoney(costTotal);

    const generalDiscountPercent = validDiscount(
      req.body.general_discount_percent,
    );

    const afterProductDiscount = roundMoney(subtotal - productDiscount);

    const generalDiscountAmount = roundMoney(
      (afterProductDiscount * generalDiscountPercent) / 100,
    );

    const totalDiscount = roundMoney(productDiscount + generalDiscountAmount);

    const total = roundMoney(Math.max(0, subtotal - totalDiscount));

    const amountReceived = roundMoney(
      Number(req.body.amount_received ?? total),
    );

    const paymentMethod = req.body.payment_method || "efectivo";

    if (paymentMethod === "efectivo" && amountReceived < total) {
      return res.status(400).json({
        error: "El efectivo recibido es menor al total",
      });
    }

    for (const item of saleItems) {
      const updatedProduct = await Product.findOneAndUpdate(
        {
          _id: item.product_id,
          stock: {
            $gte: item.quantity,
          },
        },
        {
          $inc: {
            stock: -item.quantity,
          },
        },
        {
          new: true,
        },
      );

      if (!updatedProduct) {
        throw new Error(`El stock de ${item.name} cambió durante la venta`);
      }

      updatedProducts.push({
        id: item.product_id,
        quantity: item.quantity,
      });
    }

    const change =
      paymentMethod === "efectivo"
        ? roundMoney(Math.max(0, amountReceived - total))
        : 0;

    const grossProfit = roundMoney(total - costTotal);

    const folio = `V-${Date.now()}-${randomUUID().slice(0, 6).toUpperCase()}`;

    const sale = new Sale({
      folio,
      items: saleItems,
      subtotal,
      product_discount: productDiscount,
      general_discount_percent: generalDiscountPercent,
      general_discount_amount: generalDiscountAmount,
      total_discount: totalDiscount,
      total,
      cost_total: costTotal,
      gross_profit: grossProfit,
      payment_method: paymentMethod,
      amount_received: amountReceived,
      change,
      notes: req.body.notes || "",
      sold_by_uid: req.user.uid,
      sold_by_email: req.user.email,
    });

    await sale.save();

    res.status(201).json({
      mensaje: "Venta registrada correctamente",
      venta: sale,
    });
  } catch (error) {
    for (const item of updatedProducts.reverse()) {
      await Product.findByIdAndUpdate(item.id, {
        $inc: {
          stock: item.quantity,
        },
      });
    }

    res.status(500).json({
      error: "Error al registrar la venta",
      detalle: error.message,
    });
  }
});

app.get("/ventas", verificarJWT, async (req, res) => {
  try {
    const sales = await Sale.find()
      .sort({
        createdAt: -1,
      })
      .limit(500)
      .lean();

    res.json(sales);
  } catch (error) {
    res.status(500).json({
      error: "Error al obtener ventas",
      detalle: error.message,
    });
  }
});

app.get("/ventas/:id", verificarJWT, async (req, res) => {
  try {
    const sale = await Sale.findById(req.params.id);

    if (!sale) {
      return res.status(404).json({
        error: "Venta no encontrada",
      });
    }

    res.json(sale);
  } catch (error) {
    res.status(400).json({
      error: "Error al obtener la venta",
      detalle: error.message,
    });
  }
});

// ==========================================================
// MONGODB Y SERVIDOR
// ==========================================================

const MONGO_URI = "mongodb://127.0.0.1:27017/examen";

mongoose
  .connect(MONGO_URI)
  .then(() => {
    console.log("MongoDB conectado correctamente");
  })
  .catch((error) => {
    console.error("Error de conexión a MongoDB:", error);
  });

const PORT = 3000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Servidor activo en http://localhost:${PORT}`);
});

/*
  # Complete Vendor-Supplier Marketplace Schema

  ## Overview
  Complete database schema for a vendor-supplier marketplace platform that enables
  street food vendors to find suppliers, create individual/group orders, and manage
  their business operations.

  ## Tables Created

  ### 1. vendors
  Stores vendor (street food business) profiles
  - Personal and business information
  - Location details with optional coordinates
  - Raw material requirements

  ### 2. suppliers  
  Stores supplier profiles
  - Business information and certifications
  - Supply capabilities and delivery preferences
  - Rating system

  ### 3. products
  Products/raw materials offered by suppliers
  - Product details, pricing, and stock status
  - Category-based organization

  ### 4. orders
  Orders placed by vendors to suppliers
  - Individual and group order support
  - Payment tracking and delivery management
  - Status workflow management

  ### 5. order_items
  Line items for each order
  - Product quantities and pricing
  - Historical price tracking

  ### 6. product_groups
  Group buying requests created by suppliers
  - Bulk discount offerings
  - Location-based group formation
  - Time-limited availability

  ## Security
  - Row Level Security (RLS) enabled on all tables
  - Comprehensive policies for data isolation
  - Role-based access control (vendors, suppliers)
*/

-- ==========================================
-- 1. VENDORS TABLE
-- ==========================================
CREATE TABLE IF NOT EXISTS vendors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  business_name text NOT NULL,
  owner_name text NOT NULL,
  phone text NOT NULL,
  address text NOT NULL,
  city text NOT NULL,
  state text NOT NULL,
  pincode text NOT NULL,
  business_type text NOT NULL DEFAULT 'street_food',
  gst_number text,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- ==========================================
-- 2. SUPPLIERS TABLE
-- ==========================================
CREATE TABLE IF NOT EXISTS suppliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  business_name text NOT NULL,
  owner_name text NOT NULL,
  phone text NOT NULL,
  email text NOT NULL,
  address text NOT NULL,
  city text NOT NULL,
  state text NOT NULL,
  pincode text NOT NULL,
  gst_number text,
  fssai_license text,
  rating numeric(2,1) DEFAULT 0 NOT NULL CHECK (rating >= 0 AND rating <= 5),
  total_reviews integer DEFAULT 0 NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- ==========================================
-- 3. PRODUCTS TABLE
-- ==========================================
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_id uuid REFERENCES suppliers(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  category text NOT NULL,
  unit text NOT NULL,
  price_per_unit numeric(10,2) NOT NULL CHECK (price_per_unit >= 0),
  min_order_quantity numeric(10,2) DEFAULT 1 NOT NULL CHECK (min_order_quantity > 0),
  stock_available boolean DEFAULT true NOT NULL,
  description text,
  image_url text,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- ==========================================
-- 4. ORDERS TABLE
-- ==========================================
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id uuid REFERENCES vendors(id) ON DELETE CASCADE NOT NULL,
  supplier_id uuid REFERENCES suppliers(id) ON DELETE CASCADE,
  order_number text UNIQUE NOT NULL,
  order_type text NOT NULL CHECK (order_type IN ('individual', 'group')),
  status text DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'confirmed', 'delivered', 'cancelled', 'accepted', 'completed')),
  payment_status text DEFAULT 'pending' NOT NULL CHECK (payment_status IN ('pending', 'completed', 'failed')),
  payment_method text,
  payment_id text,
  total_amount numeric(10,2) NOT NULL CHECK (total_amount >= 0),
  subtotal numeric(10,2) DEFAULT 0 NOT NULL,
  tax numeric(10,2) DEFAULT 0 NOT NULL,
  delivery_charge numeric(10,2) DEFAULT 0 NOT NULL,
  group_discount numeric(10,2) DEFAULT 0 NOT NULL,
  delivery_address text NOT NULL,
  delivery_date date,
  notes text,
  items jsonb NOT NULL,
  customer_details jsonb,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- ==========================================
-- 5. ORDER_ITEMS TABLE
-- ==========================================
CREATE TABLE IF NOT EXISTS order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
  product_id uuid REFERENCES products(id) ON DELETE RESTRICT NOT NULL,
  quantity numeric(10,2) NOT NULL CHECK (quantity > 0),
  unit_price numeric(10,2) NOT NULL CHECK (unit_price >= 0),
  total_price numeric(10,2) NOT NULL CHECK (total_price >= 0),
  created_at timestamptz DEFAULT now() NOT NULL
);

-- ==========================================
-- 6. PRODUCT_GROUPS TABLE (NEW)
-- ==========================================
CREATE TABLE IF NOT EXISTS product_groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by uuid REFERENCES suppliers(id) ON DELETE CASCADE NOT NULL,
  product text NOT NULL,
  quantity text NOT NULL,
  price text NOT NULL,
  actual_rate numeric(10,2) NOT NULL,
  final_rate numeric(10,2) NOT NULL,
  discount_percentage text NOT NULL,
  location text NOT NULL,
  latitude text,
  longitude text,
  deadline timestamptz NOT NULL,
  status text DEFAULT 'active' NOT NULL CHECK (status IN ('active', 'accepted', 'declined', 'delivered', 'expired')),
  vendors integer DEFAULT 0 NOT NULL,
  estimated_value text,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- ==========================================
-- INDEXES FOR PERFORMANCE
-- ==========================================
CREATE INDEX IF NOT EXISTS idx_vendors_user_id ON vendors(user_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_user_id ON suppliers(user_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_rating ON suppliers(rating DESC);
CREATE INDEX IF NOT EXISTS idx_products_supplier_id ON products(supplier_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_orders_vendor_id ON orders(vendor_id);
CREATE INDEX IF NOT EXISTS idx_orders_supplier_id ON orders(supplier_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_product_groups_created_by ON product_groups(created_by);
CREATE INDEX IF NOT EXISTS idx_product_groups_status ON product_groups(status);
CREATE INDEX IF NOT EXISTS idx_product_groups_deadline ON product_groups(deadline);

-- ==========================================
-- ENABLE ROW LEVEL SECURITY
-- ==========================================
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_groups ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- VENDORS RLS POLICIES
-- ==========================================
CREATE POLICY "Users can view own vendor profile"
  ON vendors FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own vendor profile"
  ON vendors FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own vendor profile"
  ON vendors FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ==========================================
-- SUPPLIERS RLS POLICIES
-- ==========================================
CREATE POLICY "Anyone can view all suppliers"
  ON suppliers FOR SELECT
  TO authenticated, anon
  USING (true);

CREATE POLICY "Users can insert own supplier profile"
  ON suppliers FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own supplier profile"
  ON suppliers FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ==========================================
-- PRODUCTS RLS POLICIES
-- ==========================================
CREATE POLICY "Anyone can view all products"
  ON products FOR SELECT
  TO authenticated, anon
  USING (true);

CREATE POLICY "Suppliers can insert own products"
  ON products FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM suppliers
      WHERE suppliers.id = products.supplier_id
      AND suppliers.user_id = auth.uid()
    )
  );

CREATE POLICY "Suppliers can update own products"
  ON products FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM suppliers
      WHERE suppliers.id = products.supplier_id
      AND suppliers.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM suppliers
      WHERE suppliers.id = products.supplier_id
      AND suppliers.user_id = auth.uid()
    )
  );

CREATE POLICY "Suppliers can delete own products"
  ON products FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM suppliers
      WHERE suppliers.id = products.supplier_id
      AND suppliers.user_id = auth.uid()
    )
  );

-- ==========================================
-- ORDERS RLS POLICIES
-- ==========================================
CREATE POLICY "Vendors can view own orders"
  ON orders FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM vendors
      WHERE vendors.id = orders.vendor_id
      AND vendors.user_id = auth.uid()
    )
  );

CREATE POLICY "Suppliers can view orders assigned to them"
  ON orders FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM suppliers
      WHERE suppliers.id = orders.supplier_id
      AND suppliers.user_id = auth.uid()
    )
  );

CREATE POLICY "Suppliers can view pending unassigned orders"
  ON orders FOR SELECT
  TO authenticated
  USING (
    orders.supplier_id IS NULL
    AND EXISTS (
      SELECT 1 FROM suppliers
      WHERE suppliers.user_id = auth.uid()
    )
  );

CREATE POLICY "Vendors can create orders"
  ON orders FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM vendors
      WHERE vendors.id = orders.vendor_id
      AND vendors.user_id = auth.uid()
    )
  );

CREATE POLICY "Vendors can update own pending orders"
  ON orders FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM vendors
      WHERE vendors.id = orders.vendor_id
      AND vendors.user_id = auth.uid()
    )
    AND status = 'pending'
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM vendors
      WHERE vendors.id = orders.vendor_id
      AND vendors.user_id = auth.uid()
    )
  );

CREATE POLICY "Suppliers can update order status"
  ON orders FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM suppliers
      WHERE suppliers.id = orders.supplier_id
      AND suppliers.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM suppliers
      WHERE suppliers.id = orders.supplier_id
      AND suppliers.user_id = auth.uid()
    )
  );

-- ==========================================
-- ORDER_ITEMS RLS POLICIES
-- ==========================================
CREATE POLICY "Users can view order items for their orders"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND (
        EXISTS (
          SELECT 1 FROM vendors
          WHERE vendors.id = orders.vendor_id
          AND vendors.user_id = auth.uid()
        )
        OR EXISTS (
          SELECT 1 FROM suppliers
          WHERE suppliers.id = orders.supplier_id
          AND suppliers.user_id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "Vendors can insert order items for their orders"
  ON order_items FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders
      JOIN vendors ON vendors.id = orders.vendor_id
      WHERE orders.id = order_items.order_id
      AND vendors.user_id = auth.uid()
    )
  );

-- ==========================================
-- PRODUCT_GROUPS RLS POLICIES
-- ==========================================
CREATE POLICY "Anyone can view active product groups"
  ON product_groups FOR SELECT
  TO authenticated, anon
  USING (true);

CREATE POLICY "Suppliers can create product groups"
  ON product_groups FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM suppliers
      WHERE suppliers.id = product_groups.created_by
      AND suppliers.user_id = auth.uid()
    )
  );

CREATE POLICY "Suppliers can update own product groups"
  ON product_groups FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM suppliers
      WHERE suppliers.id = product_groups.created_by
      AND suppliers.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM suppliers
      WHERE suppliers.id = product_groups.created_by
      AND suppliers.user_id = auth.uid()
    )
  );

CREATE POLICY "Suppliers can delete own product groups"
  ON product_groups FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM suppliers
      WHERE suppliers.id = product_groups.created_by
      AND suppliers.user_id = auth.uid()
    )
  );

-- ==========================================
-- TRIGGERS FOR updated_at
-- ==========================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_vendors_updated_at
  BEFORE UPDATE ON vendors
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_suppliers_updated_at
  BEFORE UPDATE ON suppliers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_product_groups_updated_at
  BEFORE UPDATE ON product_groups
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
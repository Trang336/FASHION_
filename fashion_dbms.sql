-- =====================================================
-- HỆ THỐNG QUẢN LÝ BÁN QUẦN ÁO - PHIÊN BẢN ĐẦY ĐỦ v2
-- SQL Server | Đồ án môn CSDL nâng cao
-- Bao gồm: Schema + Mock Data + 10 Views + 10 Procedures
--          + 10 Functions + 10 Triggers
-- =====================================================

USE master;
GO
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'ClothingStoreDB')
    DROP DATABASE ClothingStoreDB;
GO
CREATE DATABASE ClothingStoreDB
    COLLATE Vietnamese_CI_AS;
GO
USE ClothingStoreDB;
GO

-- =====================================================
-- PHẦN 1: TẠO CẤU TRÚC BẢNG
-- =====================================================

-- 1.1 ROLES & PERMISSIONS
CREATE TABLE Roles (
    role_id     INT PRIMARY KEY IDENTITY(1,1),
    role_name   NVARCHAR(50)  NOT NULL UNIQUE,
    description NVARCHAR(200)
);

CREATE TABLE Permissions (
    permission_id INT PRIMARY KEY IDENTITY(1,1),
    module        NVARCHAR(50) NOT NULL,
    action        NVARCHAR(50) NOT NULL,
    CONSTRAINT UQ_perm UNIQUE (module, action)
);

CREATE TABLE RolePermissions (
    role_id       INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id)       REFERENCES Roles(role_id),
    FOREIGN KEY (permission_id) REFERENCES Permissions(permission_id)
);

-- 1.2 USERS
CREATE TABLE Users (
    user_id       INT PRIMARY KEY IDENTITY(1,1),
    role_id       INT          NOT NULL,
    full_name     NVARCHAR(100) NOT NULL,
    email         NVARCHAR(100) NOT NULL UNIQUE,
    phone         VARCHAR(15),
    password_hash VARCHAR(255)  NOT NULL,
    is_active     BIT           DEFAULT 1,
    created_at    DATETIME      DEFAULT GETDATE(),
    FOREIGN KEY (role_id) REFERENCES Roles(role_id)
);

-- 1.3 CATEGORIES (tự tham chiếu cha-con)
CREATE TABLE Categories (
    category_id   INT PRIMARY KEY IDENTITY(1,1),
    parent_id     INT NULL,
    category_name NVARCHAR(100) NOT NULL,
    slug          VARCHAR(100),
    FOREIGN KEY (parent_id) REFERENCES Categories(category_id)
);

-- 1.4 BRANDS
CREATE TABLE Brands (
    brand_id   INT PRIMARY KEY IDENTITY(1,1),
    brand_name NVARCHAR(100) NOT NULL,
    country    NVARCHAR(50),
    logo_url   VARCHAR(255)
);

-- 1.5 PRODUCTS (không chứa size/màu)
CREATE TABLE Products (
    product_id   INT PRIMARY KEY IDENTITY(1,1),
    category_id  INT           NOT NULL,
    brand_id     INT           NOT NULL,
    product_name NVARCHAR(200) NOT NULL,
    description  NVARCHAR(MAX),
    base_price   DECIMAL(12,2) NOT NULL,
    is_active    BIT           DEFAULT 1,
    created_at   DATETIME      DEFAULT GETDATE(),
    CONSTRAINT CHK_product_base_price CHECK (base_price > 0),   -- [FIX] giá không được <= 0
    FOREIGN KEY (category_id) REFERENCES Categories(category_id),
    FOREIGN KEY (brand_id)    REFERENCES Brands(brand_id)
);

-- 1.6 PRODUCT VARIANTS (size + màu tách hoàn toàn khỏi Products)
CREATE TABLE ProductVariants (
    variant_id  INT PRIMARY KEY IDENTITY(1,1),
    product_id  INT           NOT NULL,
    size        NVARCHAR(10),        -- XS/S/M/L/XL/XXL hoặc 28/30/32/34
    color       NVARCHAR(50),
    sku         VARCHAR(60)   NOT NULL UNIQUE,
    extra_price DECIMAL(12,2) DEFAULT 0,
    image_url   VARCHAR(255),
    CONSTRAINT CHK_variant_extra_price CHECK (extra_price >= 0),  -- [FIX]
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- 1.7 WAREHOUSES
CREATE TABLE Warehouses (
    warehouse_id   INT PRIMARY KEY IDENTITY(1,1),
    warehouse_name NVARCHAR(100) NOT NULL,
    address        NVARCHAR(300)
);

-- 1.8 INVENTORY: (variant_id, warehouse_id) → quantity
CREATE TABLE Inventory (
    inventory_id INT PRIMARY KEY IDENTITY(1,1),
    variant_id   INT NOT NULL,
    warehouse_id INT NOT NULL,
    quantity     INT DEFAULT 0,
    min_quantity INT DEFAULT 5,
    updated_at   DATETIME DEFAULT GETDATE(),
    CONSTRAINT UQ_inv      UNIQUE (variant_id, warehouse_id),
    CONSTRAINT CHK_inv_qty CHECK (quantity >= 0),        -- [FIX] không cho tồn kho âm tại INSERT
    CONSTRAINT CHK_inv_min CHECK (min_quantity >= 0),    -- [FIX]
    FOREIGN KEY (variant_id)   REFERENCES ProductVariants(variant_id),
    FOREIGN KEY (warehouse_id) REFERENCES Warehouses(warehouse_id)
);

-- 1.9 SUPPLIERS
CREATE TABLE Suppliers (
    supplier_id    INT PRIMARY KEY IDENTITY(1,1),
    supplier_name  NVARCHAR(200) NOT NULL,
    contact_person NVARCHAR(100),
    phone          VARCHAR(15),
    email          NVARCHAR(100),
    address        NVARCHAR(300),
    is_active      BIT DEFAULT 1
);

-- 1.10 STOCK RECEIPTS (phiếu nhập kho)
CREATE TABLE StockReceipts (
    receipt_id   INT PRIMARY KEY IDENTITY(1,1),
    supplier_id  INT  NOT NULL,
    warehouse_id INT  NOT NULL,
    created_by   INT  NOT NULL,
    receipt_date DATETIME DEFAULT GETDATE(),
    total_amount DECIMAL(14,2),
    note         NVARCHAR(300),
    FOREIGN KEY (supplier_id)  REFERENCES Suppliers(supplier_id),
    FOREIGN KEY (warehouse_id) REFERENCES Warehouses(warehouse_id),
    FOREIGN KEY (created_by)   REFERENCES Users(user_id)
);

CREATE TABLE StockReceiptItems (
    item_id    INT PRIMARY KEY IDENTITY(1,1),
    receipt_id INT           NOT NULL,
    variant_id INT           NOT NULL,
    quantity   INT           NOT NULL,
    unit_cost  DECIMAL(12,2) NOT NULL,
    CONSTRAINT CHK_sri_qty  CHECK (quantity > 0),      -- [FIX]
    CONSTRAINT CHK_sri_cost CHECK (unit_cost > 0),     -- [FIX]
    FOREIGN KEY (receipt_id) REFERENCES StockReceipts(receipt_id),
    FOREIGN KEY (variant_id) REFERENCES ProductVariants(variant_id)
);

-- 1.11 CUSTOMERS
CREATE TABLE Customers (
    customer_id    INT PRIMARY KEY IDENTITY(1,1),
    full_name      NVARCHAR(100) NOT NULL,
    email          NVARCHAR(100),
    phone          VARCHAR(15),
    address        NVARCHAR(300),
    gender         NVARCHAR(10),
    birthday       DATE,
    loyalty_points INT      DEFAULT 0,
    created_at     DATETIME DEFAULT GETDATE()
);

-- 1.12 ORDERS
CREATE TABLE Orders (
    order_id          INT PRIMARY KEY IDENTITY(1,1),
    customer_id       INT           NOT NULL,
    created_by        INT           NOT NULL,
    order_date        DATETIME      DEFAULT GETDATE(),
    status            NVARCHAR(30)  DEFAULT 'pending',
    shipping_address  NVARCHAR(300),
    discount_amount   DECIMAL(12,2) DEFAULT 0,
    total_amount      DECIMAL(14,2) NOT NULL,
    note              NVARCHAR(300),
    -- [FIX] Cờ reserve stock: 1 = đã trừ kho lúc đặt hàng, 0 = chưa trừ
    --       Dùng để tránh double-deduct khi trigger trg_DeductStockOnDelivered chạy
    is_stock_reserved BIT           DEFAULT 0,
    -- [FIX] Ràng buộc status — tránh bypass qua UPDATE trực tiếp
    CONSTRAINT CHK_order_status   CHECK (status IN ('pending','confirmed','shipping','shipped','delivered','cancelled')),
    CONSTRAINT CHK_order_total    CHECK (total_amount >= 0),
    CONSTRAINT CHK_order_discount CHECK (discount_amount >= 0),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (created_by)  REFERENCES Users(user_id)
);

CREATE TABLE OrderItems (
    item_id    INT PRIMARY KEY IDENTITY(1,1),
    order_id   INT           NOT NULL,
    variant_id INT           NOT NULL,
    quantity   INT           NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    CONSTRAINT CHK_oi_qty   CHECK (quantity > 0),      -- [FIX]
    CONSTRAINT CHK_oi_price CHECK (unit_price > 0),    -- [FIX]
    FOREIGN KEY (order_id)   REFERENCES Orders(order_id),
    FOREIGN KEY (variant_id) REFERENCES ProductVariants(variant_id)
);

-- 1.13 PAYMENTS
CREATE TABLE Payments (
    payment_id      INT PRIMARY KEY IDENTITY(1,1),
    order_id        INT           NOT NULL,
    payment_date    DATETIME      DEFAULT GETDATE(),
    amount          DECIMAL(14,2) NOT NULL,
    method          NVARCHAR(50),
    status          NVARCHAR(20)  DEFAULT 'completed',
    transaction_ref VARCHAR(100),
    CONSTRAINT CHK_payment_amount CHECK (amount > 0),  -- [FIX]
    CONSTRAINT CHK_payment_status CHECK (status IN ('pending','completed','failed','refunded')),  -- [FIX]
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

-- 1.14 LOG TABLE (dùng cho Triggers)
CREATE TABLE AuditLog (
    log_id     INT PRIMARY KEY IDENTITY(1,1),
    table_name NVARCHAR(50),
    action     NVARCHAR(10),
    record_id  INT,
    changed_by NVARCHAR(100) DEFAULT SYSTEM_USER,
    changed_at DATETIME      DEFAULT GETDATE(),
    detail     NVARCHAR(500)
);

GO

-- =====================================================
-- PHẦN 2: INSERT DỮ LIỆU MẪU
-- =====================================================

-- ROLES
INSERT INTO Roles (role_name, description) VALUES
(N'Admin',           N'Toàn quyền hệ thống'),
(N'Manager',         N'Quản lý cửa hàng, xem báo cáo'),
(N'Sales Staff',     N'Nhân viên bán hàng'),
(N'Warehouse Staff', N'Nhân viên kho'),
(N'Viewer',          N'Chỉ xem báo cáo');

-- PERMISSIONS
INSERT INTO Permissions (module, action) VALUES
('products','read'),('products','create'),('products','update'),('products','delete'),
('inventory','read'),('inventory','create'),('inventory','update'),('inventory','delete'),
('orders','read'),('orders','create'),('orders','update'),('orders','delete'),
('users','read'),('users','create'),('users','update'),('users','delete'),
('reports','read'),('suppliers','read'),('suppliers','create'),('suppliers','update');

-- ROLE PERMISSIONS
INSERT INTO RolePermissions (role_id, permission_id)
SELECT 1, permission_id FROM Permissions; -- Admin: tất cả

INSERT INTO RolePermissions (role_id, permission_id)  -- Manager
SELECT 2, permission_id FROM Permissions
WHERE (module IN ('products','inventory','orders','reports','suppliers') AND action IN ('read','update'))
   OR (module = 'orders' AND action = 'create');

INSERT INTO RolePermissions (role_id, permission_id)  -- Sales Staff
SELECT 3, permission_id FROM Permissions
WHERE (module = 'orders'   AND action IN ('read','create','update'))
   OR (module = 'products' AND action = 'read')
   OR (module = 'inventory' AND action = 'read');

INSERT INTO RolePermissions (role_id, permission_id)  -- Warehouse Staff
SELECT 4, permission_id FROM Permissions
WHERE module IN ('inventory','suppliers') AND action IN ('read','create','update');

INSERT INTO RolePermissions (role_id, permission_id)  -- Viewer
SELECT 5, permission_id FROM Permissions
WHERE action = 'read';

-- USERS (ít nhất 1 user mỗi role)
INSERT INTO Users (role_id, full_name, email, phone, password_hash) VALUES
(1, N'Nguyễn Văn Admin',      'admin@store.vn',      '0901000001', 'hash_admin'),
(2, N'Trần Thị Manager',      'manager@store.vn',    '0901000002', 'hash_mgr'),
(3, N'Lê Văn Sales 1',        'sales1@store.vn',     '0901000003', 'hash_s1'),
(3, N'Phạm Thị Sales 2',      'sales2@store.vn',     '0901000004', 'hash_s2'),
(3, N'Ngô Thị Sales 3',       'sales3@store.vn',     '0901000006', 'hash_s3'),
(4, N'Hoàng Văn Warehouse',   'warehouse@store.vn',  '0901000005', 'hash_wh'),
(5, N'Vũ Minh Viewer',        'viewer@store.vn',     '0901000007', 'hash_vw');

-- CATEGORIES (cha → con)
INSERT INTO Categories (parent_id, category_name, slug) VALUES
(NULL,N'Áo','ao'),           (NULL,N'Quần','quan'),
(NULL,N'Váy & Đầm','vay-dam'),(NULL,N'Phụ kiện','phu-kien'),
(1,N'Áo thun','ao-thun'),    (1,N'Áo sơ mi','ao-so-mi'),
(1,N'Áo khoác','ao-khoac'),  (1,N'Áo hoodie','ao-hoodie'),
(2,N'Quần jean','quan-jean'),(2,N'Quần kaki','quan-kaki'),
(2,N'Quần short','quan-short'),(3,N'Váy ngắn','vay-ngan'),
(3,N'Đầm dài','dam-dai'),    (4,N'Mũ & Nón','mu-non'),
(4,N'Thắt lưng','that-lung');

-- BRANDS
INSERT INTO Brands (brand_name, country) VALUES
(N'Local Brand VN','Việt Nam'),(N'SkyWear','Việt Nam'),
(N'UrbanFit','Việt Nam'),      (N'TrendyHouse','Việt Nam'),
(N'EcoThreads','Việt Nam'),    (N'StreetStyle Co','Việt Nam'),
(N'PureBasic','Việt Nam'),     (N'NightOwl Apparel','Việt Nam');

-- WAREHOUSES
INSERT INTO Warehouses (warehouse_name, address) VALUES
(N'Kho Hà Nội',       N'123 Đường Láng, Đống Đa, Hà Nội'),
(N'Kho Hồ Chí Minh',  N'456 Lý Thường Kiệt, Q.10, TP.HCM'),
(N'Kho Đà Nẵng',      N'789 Nguyễn Văn Linh, Đà Nẵng');

-- SUPPLIERS
INSERT INTO Suppliers (supplier_name, contact_person, phone, email, address) VALUES
(N'Dệt may Phong Phú',  N'Nguyễn Thành Long','0281000001','phongphu@sup.vn', N'Bình Dương'),
(N'Xưởng may Hoàng Gia',N'Trần Minh Hoàng',  '0281000002','hoanggia@sup.vn', N'TP.HCM'),
(N'Vải Việt Tiến',      N'Lê Thị Thu',       '0281000003','viettien@sup.vn', N'Long An'),
(N'May mặc An Phát',    N'Phạm Văn An',      '0281000004','anphat@sup.vn',   N'Hà Nội'),
(N'Xưởng Minh Tâm',     N'Võ Minh Tâm',      '0281000005','minhtam@sup.vn',  N'Đà Nẵng');

-- PRODUCTS (~150 sản phẩm, KHÔNG có size/màu)
INSERT INTO Products (category_id, brand_id, product_name, base_price) VALUES
-- Áo thun (cat 5) × 20
(5,1,N'Áo thun nam basic trắng',150000),(5,1,N'Áo thun nam basic đen',150000),
(5,2,N'Áo thun SkyWear cổ tròn',180000),(5,2,N'Áo thun SkyWear in logo',200000),
(5,3,N'Áo thun UrbanFit oversize',220000),(5,3,N'Áo thun UrbanFit crop',190000),
(5,4,N'Áo thun TrendyHouse sọc',175000),(5,5,N'Áo thun EcoThreads cotton',210000),
(5,6,N'Áo thun StreetStyle tie-dye',230000),(5,7,N'Áo thun PureBasic ribbed',165000),
(5,1,N'Áo thun nữ cổ V basic',155000),(5,2,N'Áo thun nữ SkyWear lụa',195000),
(5,3,N'Áo thun UrbanFit puff sleeve',205000),(5,4,N'Áo thun TrendyHouse bướm',185000),
(5,8,N'Áo thun NightOwl in hình',240000),(5,5,N'Áo thun EcoThreads tái chế',215000),
(5,1,N'Áo thun polo basic',190000),(5,2,N'Áo thun polo cổ bẻ',220000),
(5,6,N'Áo thun graphic tee',235000),(5,7,N'Áo thun sport mesh',195000),
-- Áo sơ mi (cat 6) × 12
(6,1,N'Áo sơ mi nam trắng',280000),(6,2,N'Áo sơ mi kẻ caro',320000),
(6,3,N'Áo sơ mi linen',350000),(6,4,N'Áo sơ mi ngắn tay',290000),
(6,5,N'Áo sơ mi bamboo',380000),(6,6,N'Áo sơ mi denim',400000),
(6,7,N'Áo sơ mi Oxford',310000),(6,8,N'Áo sơ mi flannel',360000),
(6,1,N'Áo sơ mi nữ basic',270000),(6,2,N'Áo sơ mi nữ lụa',330000),
(6,3,N'Áo sơ mi oversized',340000),(6,4,N'Áo sơ mi Hawaii',305000),
-- Áo khoác (cat 7) × 12
(7,1,N'Áo khoác bomber basic',450000),(7,2,N'Áo khoác windbreaker',520000),
(7,3,N'Áo khoác denim',550000),(7,4,N'Áo khoác puffer',680000),
(7,5,N'Áo khoác EcoThreads',590000),(7,6,N'Áo khoác oversized',480000),
(7,7,N'Áo khoác blazer',720000),(7,8,N'Áo khoác NightOwl',850000),
(7,4,N'Áo khoác hoodie zip',580000),(7,5,N'Áo khoác rain jacket',610000),
(7,6,N'Áo khoác teddy',640000),(7,7,N'Áo khoác trench',780000),
-- Áo hoodie (cat 8) × 10
(8,1,N'Hoodie basic không mũ',320000),(8,2,N'Hoodie có mũ',380000),
(8,3,N'Hoodie crop',360000),(8,4,N'Hoodie in chữ',350000),
(8,5,N'Hoodie fleece',410000),(8,6,N'Hoodie tie-dye',395000),
(8,7,N'Hoodie waffle',370000),(8,8,N'Hoodie zip-up',420000),
(8,5,N'Hoodie zip dày',440000),(8,7,N'Hoodie basic zip',390000),
-- Quần jean (cat 9) × 15
(9,1,N'Quần jean slim xanh nhạt',420000),(9,2,N'Quần jean skinny',450000),
(9,3,N'Quần jean wide leg',480000),(9,4,N'Quần jean boyfriend',460000),
(9,5,N'Quần jean ripped',500000),(9,6,N'Quần jean baggy',520000),
(9,7,N'Quần jean straight',430000),(9,8,N'Quần jean mom jeans',455000),
(9,1,N'Quần jean nam đen slim',440000),(9,2,N'Quần jean raw edge',470000),
(9,3,N'Quần jean high-waist',445000),(9,6,N'Quần jean tapered',510000),
(9,7,N'Quần jean flare',495000),(9,4,N'Quần jean slim đen',435000),
(9,5,N'Quần jean xanh đậm slim',425000),
-- Quần kaki (cat 10) × 10
(10,1,N'Quần kaki slim be',350000),(10,2,N'Quần kaki xanh rêu',370000),
(10,3,N'Quần kaki nâu',380000),(10,4,N'Quần kaki đen',360000),
(10,5,N'Quần kaki xám',390000),(10,6,N'Quần kaki cargo',420000),
(10,7,N'Quần kaki chinos',400000),(10,8,N'Quần kaki pleated',410000),
(10,2,N'Quần kaki slim xanh',375000),(10,3,N'Quần kaki linen',395000),
-- Quần short (cat 11) × 8
(11,1,N'Quần short thể thao',180000),(11,2,N'Quần short cotton',200000),
(11,3,N'Quần short linen',220000),(11,4,N'Quần short denim',240000),
(11,5,N'Quần short EcoThreads',210000),(11,6,N'Quần short cargo',230000),
(11,7,N'Quần short basic',195000),(11,8,N'Quần short board',250000),
-- Váy ngắn (cat 12) × 10
(12,1,N'Váy ngắn hoa nhí',280000),(12,2,N'Váy ngắn chữ A',310000),
(12,3,N'Váy ngắn tennis',340000),(12,4,N'Váy ngắn denim',320000),
(12,5,N'Váy ngắn linen',295000),(12,6,N'Váy ngắn midi',330000),
(12,7,N'Váy ngắn xếp ly',285000),(12,8,N'Váy ngắn da',380000),
(12,1,N'Váy ngắn hoa cúc',270000),(12,3,N'Váy ngắn pleated',355000),
-- Đầm dài (cat 13) × 10
(13,1,N'Đầm dài hoa mùa hè',380000),(13,2,N'Đầm dài lụa',450000),
(13,3,N'Đầm dài boho',420000),(13,4,N'Đầm dài maxi',480000),
(13,5,N'Đầm dài cotton',400000),(13,6,N'Đầm dài wrap',430000),
(13,7,N'Đầm dài bodycon',460000),(13,8,N'Đầm dài velvet',520000),
(13,2,N'Đầm dài satin',470000),(13,4,N'Đầm dài florals',495000),
-- Mũ & Nón (cat 14) × 6
(14,1,N'Mũ bucket basic',120000),(14,2,N'Nón bóng chày',140000),
(14,3,N'Mũ beanie len',130000),(14,4,N'Nón lưỡi trai',150000),
(14,5,N'Mũ fedora rơm',160000),(14,6,N'Nón snapback',155000),
-- Thắt lưng (cat 15) × 4
(15,1,N'Thắt lưng da bò nam',180000),(15,2,N'Thắt lưng vải',150000),
(15,3,N'Thắt lưng canvas',160000),(15,4,N'Thắt lưng nữ',170000);

GO

-- PRODUCT VARIANTS
-- Mỗi sản phẩm có 2-4 variants (size × màu) → tổng ~320 variants cho 150 sản phẩm
-- Áo thun (product 1-20): size S/M/L/XL × 2 màu = 4 variants/sp
DECLARE @p INT = 1;
DECLARE @sizes TABLE (sz NVARCHAR(10), ord INT);
DECLARE @colors TABLE (col NVARCHAR(50), cod VARCHAR(3));

INSERT INTO @sizes VALUES ('S',1),('M',2),('L',3),('XL',4);
INSERT INTO @colors VALUES (N'Trắng','TRG'),(N'Đen','DEN');

WHILE @p <= 20
BEGIN
    INSERT INTO ProductVariants (product_id, size, color, sku, extra_price)
    SELECT @p, sz, col,
           'AT-' + RIGHT('000'+CAST(@p AS VARCHAR),3) + '-' + sz + '-' + cod,
           CASE WHEN sz='XL' THEN 20000 ELSE 0 END
    FROM @sizes CROSS JOIN @colors;
    SET @p = @p + 1;
END
GO

DECLARE @p INT = 21;
DECLARE @szShirt TABLE (sz NVARCHAR(10));
DECLARE @colShirt TABLE (col NVARCHAR(50), cod VARCHAR(3));
INSERT INTO @szShirt VALUES ('S'),('M'),('L'),('XL');
INSERT INTO @colShirt VALUES (N'Trắng','TRG'),(N'Xanh nhạt','XN');

WHILE @p <= 32
BEGIN
    INSERT INTO ProductVariants (product_id, size, color, sku, extra_price)
    SELECT @p, sz, col,
           'SM-' + RIGHT('000'+CAST(@p AS VARCHAR),3) + '-' + sz + '-' + cod,
           CASE WHEN sz='XL' THEN 20000 ELSE 0 END
    FROM @szShirt CROSS JOIN @colShirt;
    SET @p = @p + 1;
END
GO

DECLARE @p INT = 33;
DECLARE @szJacket TABLE (sz NVARCHAR(10));
DECLARE @colJacket TABLE (col NVARCHAR(50), cod VARCHAR(3));
INSERT INTO @szJacket VALUES ('M'),('L'),('XL'),('XXL');
INSERT INTO @colJacket VALUES (N'Đen','DEN'),(N'Xanh','XAN');

WHILE @p <= 44
BEGIN
    INSERT INTO ProductVariants (product_id, size, color, sku, extra_price)
    SELECT @p, sz, col,
           'AK-' + RIGHT('000'+CAST(@p AS VARCHAR),3) + '-' + sz + '-' + cod,
           CASE WHEN sz='XXL' THEN 50000 ELSE 0 END
    FROM @szJacket CROSS JOIN @colJacket;
    SET @p = @p + 1;
END
GO

DECLARE @p INT = 45;
DECLARE @szH TABLE (sz NVARCHAR(10));
DECLARE @colH TABLE (col NVARCHAR(50), cod VARCHAR(3));
INSERT INTO @szH VALUES ('S'),('M'),('L'),('XL');
INSERT INTO @colH VALUES (N'Xám','XAM'),(N'Đen','DEN');

WHILE @p <= 54
BEGIN
    INSERT INTO ProductVariants (product_id, size, color, sku, extra_price)
    SELECT @p, sz, col,
           'HD-' + RIGHT('000'+CAST(@p AS VARCHAR),3) + '-' + sz + '-' + cod,
           CASE WHEN sz='XL' THEN 30000 ELSE 0 END
    FROM @szH CROSS JOIN @colH;
    SET @p = @p + 1;
END
GO

DECLARE @p INT = 55;
DECLARE @szJ TABLE (sz NVARCHAR(10));
DECLARE @colJ TABLE (col NVARCHAR(50), cod VARCHAR(3));
INSERT INTO @szJ VALUES ('28'),('30'),('32'),('34');
INSERT INTO @colJ VALUES (N'Xanh nhạt','XN'),(N'Đen','DEN');

WHILE @p <= 69
BEGIN
    INSERT INTO ProductVariants (product_id, size, color, sku, extra_price)
    SELECT @p, sz, col,
           'QJ-' + RIGHT('000'+CAST(@p AS VARCHAR),3) + '-' + sz + '-' + cod,
           CASE WHEN sz='34' THEN 30000 ELSE 0 END
    FROM @szJ CROSS JOIN @colJ;
    SET @p = @p + 1;
END
GO

-- Kaki, short, váy, đầm, phụ kiện (3 size × 2 màu)
DECLARE @p INT = 70;
DECLARE @sz3 TABLE (sz NVARCHAR(10));
DECLARE @col3 TABLE (col NVARCHAR(50), cod VARCHAR(4));
INSERT INTO @sz3 VALUES ('S'),('M'),('L');
INSERT INTO @col3 VALUES (N'Be','BE'),(N'Xanh rêu','XR');

WHILE @p <= 117
BEGIN
    DECLARE @prefix VARCHAR(4) =
        CASE WHEN @p BETWEEN 70 AND 79  THEN 'QK'
             WHEN @p BETWEEN 80 AND 87  THEN 'QS'
             WHEN @p BETWEEN 88 AND 97  THEN 'VN'
             WHEN @p BETWEEN 98 AND 107 THEN 'DD'
             ELSE 'PK' END;
    INSERT INTO ProductVariants (product_id, size, color, sku, extra_price)
    SELECT @p, sz, col,
           @prefix + '-' + RIGHT('000'+CAST(@p AS VARCHAR),3) + '-' + sz + '-' + cod, 0
    FROM @sz3 CROSS JOIN @col3;
    SET @p = @p + 1;
END
GO

-- INVENTORY: mỗi variant × 3 kho
INSERT INTO Inventory (variant_id, warehouse_id, quantity, min_quantity)
SELECT v.variant_id, w.warehouse_id,
       ABS(CHECKSUM(NEWID())) % 91 + 10,   -- 10-100
       5
FROM ProductVariants v
CROSS JOIN Warehouses w;

-- CUSTOMERS (25 khách hàng)
INSERT INTO Customers (full_name, email, phone, address, gender, birthday, loyalty_points) VALUES
(N'Nguyễn Thị Hoa',    'hoa@gmail.com',    '0901111001',N'Q1, TP.HCM',        N'Nữ', '1995-03-12',250),
(N'Trần Văn Bình',     'binh@gmail.com',   '0901111002',N'Ba Đình, HN',        N'Nam','1992-07-20',180),
(N'Lê Thị Mai',        'mai@gmail.com',    '0901111003',N'Hải Châu, ĐN',       N'Nữ', '1998-11-05',90),
(N'Phạm Quốc Hùng',   'hung@gmail.com',   '0901111004',N'Q3, TP.HCM',         N'Nam','1990-01-15',320),
(N'Hoàng Thị Linh',   'linh@gmail.com',   '0901111005',N'Hoàn Kiếm, HN',      N'Nữ', '1997-05-22',75),
(N'Vũ Minh Khôi',     'khoi@gmail.com',   '0901111006',N'Q7, TP.HCM',         N'Nam','1993-09-30',410),
(N'Đặng Thị Yến',     'yen@gmail.com',    '0901111007',N'Thanh Khê, ĐN',      N'Nữ', '1999-02-14',60),
(N'Bùi Văn Đức',      'duc@gmail.com',    '0901111008',N'Cầu Giấy, HN',       N'Nam','1988-12-03',200),
(N'Ngô Thị Thanh',    'thanh@gmail.com',  '0901111009',N'Bình Thạnh, HCM',    N'Nữ', '1996-06-18',130),
(N'Dương Văn Tùng',   'tung@gmail.com',   '0901111010',N'Q5, TP.HCM',         N'Nam','1994-04-07',290),
(N'Phan Thị Ngọc',    'ngoc@gmail.com',   '0901111011',N'Liên Chiểu, ĐN',     N'Nữ', '2000-08-25',45),
(N'Tô Văn Hải',       'hai@gmail.com',    '0901111012',N'Đống Đa, HN',        N'Nam','1991-10-11',160),
(N'Lý Thị Kim Anh',   'kimanh@gmail.com', '0901111013',N'Tân Bình, HCM',      N'Nữ', '1997-03-28',220),
(N'Trương Công Minh', 'minh@gmail.com',   '0901111014',N'Long Biên, HN',      N'Nam','1989-07-16',380),
(N'Cao Thị Thúy',     'thuy@gmail.com',   '0901111015',N'Hòa Vang, ĐN',       N'Nữ', '2001-12-09',30),
(N'Đinh Văn Phúc',    'phuc@gmail.com',   '0901111016',N'Q10, TP.HCM',        N'Nam','1995-05-04',140),
(N'Huỳnh Thị Diễm',   'diem@gmail.com',   '0901111017',N'Hà Đông, HN',        N'Nữ', '1998-09-13',70),
(N'Lưu Quang Trung',  'trung@gmail.com',  '0901111018',N'Ngũ Hành Sơn, ĐN',  N'Nam','1993-11-27',190),
(N'Kiều Thị Bích',    'bich@gmail.com',   '0901111019',N'Phú Nhuận, HCM',     N'Nữ', '1996-01-31',110),
(N'Mai Văn Toàn',     'toan@gmail.com',   '0901111020',N'Tây Hồ, HN',         N'Nam','1990-06-08',260),
(N'Trịnh Thị Lan',    'lan@gmail.com',    '0901111021',N'Q2, TP.HCM',         N'Nữ', '1994-08-17',85),
(N'Đỗ Văn Long',      'long@gmail.com',   '0901111022',N'Đống Đa, HN',        N'Nam','1987-03-25',340),
(N'Hà Thị Thu',       'thu@gmail.com',    '0901111023',N'Ngũ Hành Sơn, ĐN',  N'Nữ', '2002-05-30',20),
(N'Lương Văn Dũng',   'dung@gmail.com',   '0901111024',N'Q Bình Thạnh, HCM', N'Nam','1991-12-15',170),
(N'Trần Thị Ngân',    'ngan@gmail.com',   '0901111025',N'Hoàn Kiếm, HN',      N'Nữ', '1999-07-04',50);

-- STOCK RECEIPTS
INSERT INTO StockReceipts (supplier_id, warehouse_id, created_by, receipt_date, total_amount, note) VALUES
(1,1,6,'2024-01-10',15000000,N'Nhập hàng đầu năm HN'),
(2,2,6,'2024-02-15',22000000,N'Bổ sung tồn kho HCM'),
(3,1,6,'2024-03-20',18500000,N'Nhập hàng xuân hè'),
(1,3,6,'2024-04-05',12000000,N'Nhập kho Đà Nẵng'),
(4,2,6,'2024-05-12',30000000,N'Đơn hàng lớn Q2'),
(2,1,6,'2024-06-01',25000000,N'Nhập hàng hè'),
(3,3,6,'2024-07-10',19000000,N'Bổ sung kho ĐN'),
(5,2,6,'2024-08-05',21000000,N'Nhập hàng thu đông');

INSERT INTO StockReceiptItems (receipt_id, variant_id, quantity, unit_cost) VALUES
(1,1,50,90000),(1,2,50,90000),(1,3,40,90000),(1,4,30,90000),
(2,5,40,90000),(2,9,50,90000),(2,81,60,168000),(2,82,60,168000),
(3,161,50,252000),(3,162,50,252000),(3,163,40,252000),
(4,221,45,270000),(4,222,45,270000),
(5,241,70,198000),(5,242,70,198000),(5,243,50,198000),
(6,261,60,150000),(6,262,60,150000),
(7,1,30,90000),(7,5,30,90000),
(8,81,40,168000),(8,82,40,168000);

-- ORDERS (30 đơn hàng)
INSERT INTO Orders (customer_id, created_by, order_date, status, shipping_address, discount_amount, total_amount) VALUES
(1, 3,'2024-01-15 09:30','delivered', N'Q1, TP.HCM',       0,      520000),
(2, 3,'2024-01-18 14:00','delivered', N'Ba Đình, HN',       50000,  830000),
(3, 4,'2024-02-02 10:15','delivered', N'Hải Châu, ĐN',      0,      450000),
(4, 3,'2024-02-10 16:30','delivered', N'Q3, TP.HCM',        0,     1200000),
(5, 4,'2024-02-20 11:00','delivered', N'Hoàn Kiếm, HN',     100000, 680000),
(6, 3,'2024-03-05 09:00','delivered', N'Q7, TP.HCM',        0,      350000),
(7, 5,'2024-03-12 13:45','delivered', N'Thanh Khê, ĐN',     0,      590000),
(8, 3,'2024-03-22 15:20','delivered', N'Cầu Giấy, HN',      0,      960000),
(9, 4,'2024-04-01 10:30','delivered', N'Bình Thạnh, HCM',   50000,  415000),
(10,5,'2024-04-08 14:10','delivered', N'Q5, TP.HCM',        0,      780000),
(11,3,'2024-04-15 09:45','cancelled', N'Liên Chiểu, ĐN',    0,      280000),
(12,4,'2024-05-02 11:30','delivered', N'Đống Đa, HN',       0,     1050000),
(13,5,'2024-05-10 16:00','delivered', N'Tân Bình, HCM',     0,      460000),
(14,3,'2024-05-18 10:00','delivered', N'Long Biên, HN',     150000,1350000),
(15,4,'2024-06-03 13:00','delivered', N'Hòa Vang, ĐN',      0,      320000),
(16,5,'2024-06-12 09:15','shipped',   N'Q10, TP.HCM',       0,      870000),
(17,3,'2024-06-20 14:30','confirmed', N'Hà Đông, HN',       0,      540000),
(18,4,'2024-07-01 10:45','pending',   N'Ngũ Hành Sơn, ĐN',  0,      690000),
(19,5,'2024-07-08 11:00','shipped',   N'Phú Nhuận, HCM',   50000,  950000),
(20,3,'2024-07-15 15:30','pending',   N'Tây Hồ, HN',        0,      420000),
(1, 4,'2024-07-20 09:00','confirmed', N'Q1, TP.HCM',        0,      760000),
(3, 5,'2024-08-01 14:00','pending',   N'Hải Châu, ĐN',      0,      380000),
(5, 3,'2024-08-10 10:30','shipped',   N'Hoàn Kiếm, HN',     0,     1100000),
(2, 4,'2024-08-18 16:00','delivered', N'Ba Đình, HN',        0,      650000),
(6, 5,'2024-08-22 11:00','delivered', N'Q7, TP.HCM',        0,      420000),
(8, 3,'2024-09-01 10:00','delivered', N'Cầu Giấy, HN',     100000,  980000),
(10,4,'2024-09-10 14:30','shipped',   N'Q5, TP.HCM',        0,      730000),
(12,5,'2024-09-15 09:45','confirmed', N'Đống Đa, HN',       0,      560000),
(14,3,'2024-09-20 15:00','pending',   N'Long Biên, HN',     0,     1200000),
(4, 4,'2024-09-25 11:30','delivered', N'Q3, TP.HCM',       50000,   890000);

INSERT INTO OrderItems (order_id, variant_id, quantity, unit_price) VALUES
(1,1,2,150000),(1,9,1,220000),
(2,81,1,420000),(2,161,1,280000),(2,221,1,180000),
(3,241,1,180000),(3,261,1,180000),(3,1,1,150000),
(4,163,1,320000),(4,221,2,180000),(4,83,1,350000),
(5,262,2,165000),(5,162,1,190000),(5,161,1,280000),
(6,3,1,180000),(6,11,1,155000),
(7,242,1,450000),(7,5,1,180000),
(8,83,1,450000),(8,261,1,320000),(8,81,1,420000),
(9,1,1,150000),(9,241,1,120000),(9,162,1,185000),
(10,163,2,320000),(10,161,1,280000),
(11,9,1,220000),(11,5,1,205000),
(12,83,1,450000),(12,261,1,320000),(12,81,2,150000),
(13,242,1,450000),(13,161,1,280000),
(14,163,2,320000),(14,261,2,320000),(14,161,2,280000),
(15,1,1,150000),(15,241,1,140000),
(16,81,1,420000),(16,83,1,450000),
(17,161,2,280000),
(18,163,1,320000),(18,242,1,350000),
(19,83,1,450000),(19,81,1,420000),(19,261,1,320000),
(20,9,1,220000),(20,241,1,200000),
(21,161,1,350000),(21,221,2,180000),
(22,1,1,150000),(22,3,1,180000),
(23,163,2,320000),(23,261,1,320000),(23,81,1,420000),
(24,242,1,450000),(24,161,1,200000),
(25,3,1,180000),(25,11,1,240000),
(26,83,1,450000),(26,163,1,320000),(26,81,1,210000),
(27,81,1,420000),(27,242,1,310000),
(28,261,1,320000),(28,162,1,240000),
(29,163,2,320000),(29,83,1,450000),(29,161,1,130000),
(30,81,1,420000),(30,242,1,470000);

-- PAYMENTS
INSERT INTO Payments (order_id, payment_date, amount, method, status, transaction_ref) VALUES
(1, '2024-01-15',520000, N'Tiền mặt',    'completed',NULL),
(2, '2024-01-18',830000, N'Chuyển khoản','completed','TXN20240118'),
(3, '2024-02-02',450000, N'Momo',        'completed','MM20240202'),
(4, '2024-02-10',1200000,N'VNPay',       'completed','VP20240210'),
(5, '2024-02-20',680000, N'Tiền mặt',    'completed',NULL),
(6, '2024-03-05',350000, N'Chuyển khoản','completed','TXN20240305'),
(7, '2024-03-12',590000, N'Momo',        'completed','MM20240312'),
(8, '2024-03-22',960000, N'Thẻ',         'completed','CD20240322'),
(9, '2024-04-01',415000, N'Tiền mặt',    'completed',NULL),
(10,'2024-04-08',780000, N'VNPay',       'completed','VP20240408'),
(12,'2024-05-02',1050000,N'Chuyển khoản','completed','TXN20240502'),
(13,'2024-05-10',460000, N'Momo',        'completed','MM20240510'),
(14,'2024-05-18',1350000,N'Thẻ',         'completed','CD20240518'),
(15,'2024-06-03',320000, N'Tiền mặt',    'completed',NULL),
(24,'2024-08-18',650000, N'Chuyển khoản','completed','TXN20240818'),
(25,'2024-08-22',420000, N'Momo',        'completed','MM20240822'),
(26,'2024-09-01',980000, N'VNPay',       'completed','VP20240901'),
(30,'2024-09-25',890000, N'Thẻ',         'completed','CD20240925');

GO

-- =====================================================
-- PHẦN 3: 10 VIEWS
-- =====================================================

-- VIEW 1: Tồn kho theo biến thể & kho
CREATE VIEW vw_InventoryByWarehouse AS
SELECT p.product_id, p.product_name, b.brand_name, c.category_name,
       pv.variant_id, pv.size, pv.color, pv.sku,
       w.warehouse_name, i.quantity, i.min_quantity,
       (p.base_price + pv.extra_price) AS sale_price,
       CASE WHEN i.quantity <= i.min_quantity THEN N'⚠ Sắp hết' ELSE N'✔ Còn hàng' END AS stock_status
FROM Inventory i
JOIN ProductVariants pv ON i.variant_id = pv.variant_id
JOIN Products p          ON pv.product_id = p.product_id
JOIN Brands b            ON p.brand_id = b.brand_id
JOIN Categories c        ON p.category_id = c.category_id
JOIN Warehouses w        ON i.warehouse_id = w.warehouse_id;
GO

-- VIEW 2: Tồn kho thấp (cảnh báo)
CREATE VIEW vw_LowStockAlert AS
SELECT p.product_name, pv.sku, pv.size, pv.color,
       w.warehouse_name, i.quantity, i.min_quantity,
       (i.min_quantity - i.quantity) AS shortage
FROM Inventory i
JOIN ProductVariants pv ON i.variant_id = pv.variant_id
JOIN Products p          ON pv.product_id = p.product_id
JOIN Warehouses w        ON i.warehouse_id = w.warehouse_id
WHERE i.quantity <= i.min_quantity;
GO

-- VIEW 3: Tổng tồn kho theo sản phẩm (gộp tất cả kho + biến thể)
CREATE VIEW vw_TotalStockByProduct AS
SELECT p.product_id, p.product_name, b.brand_name, c.category_name,
       COUNT(DISTINCT pv.variant_id)              AS total_variants,
       SUM(i.quantity)                            AS total_stock,
       MIN(p.base_price)                          AS min_price,
       MAX(p.base_price + pv.extra_price)         AS max_price
FROM Products p
JOIN Brands b            ON p.brand_id = b.brand_id
JOIN Categories c        ON p.category_id = c.category_id
JOIN ProductVariants pv  ON pv.product_id = p.product_id
LEFT JOIN Inventory i    ON i.variant_id = pv.variant_id
GROUP BY p.product_id, p.product_name, b.brand_name, c.category_name;
GO

-- VIEW 4: Doanh thu theo ngày
CREATE VIEW vw_DailyRevenue AS
SELECT CAST(o.order_date AS DATE)  AS sale_date,
       COUNT(o.order_id)           AS total_orders,
       SUM(o.total_amount)         AS revenue,
       SUM(o.discount_amount)      AS total_discount,
       SUM(o.total_amount) - SUM(o.discount_amount) AS net_revenue
FROM Orders o
WHERE o.status = 'delivered'
GROUP BY CAST(o.order_date AS DATE);
GO

-- VIEW 5: Doanh thu theo tháng
CREATE VIEW vw_MonthlyRevenue AS
SELECT YEAR(o.order_date)  AS yr, MONTH(o.order_date) AS mo,
       COUNT(o.order_id)   AS total_orders,
       SUM(o.total_amount) AS revenue,
       AVG(o.total_amount) AS avg_order_value,
       COUNT(DISTINCT o.customer_id) AS unique_customers
FROM Orders o
WHERE o.status = 'delivered'
GROUP BY YEAR(o.order_date), MONTH(o.order_date);
GO

-- VIEW 6: Top sản phẩm bán chạy
CREATE VIEW vw_TopSellingProducts AS
SELECT p.product_id, p.product_name, b.brand_name, c.category_name,
       SUM(oi.quantity)                   AS qty_sold,
       SUM(oi.quantity * oi.unit_price)   AS revenue,
       COUNT(DISTINCT o.order_id)         AS order_count
FROM OrderItems oi
JOIN Orders o           ON oi.order_id   = o.order_id
JOIN ProductVariants pv ON oi.variant_id = pv.variant_id
JOIN Products p         ON pv.product_id = p.product_id
JOIN Brands b           ON p.brand_id    = b.brand_id
JOIN Categories c       ON p.category_id = c.category_id
WHERE o.status = 'delivered'
GROUP BY p.product_id, p.product_name, b.brand_name, c.category_name;
GO

-- VIEW 7: Chi tiết đơn hàng (order detail)
CREATE VIEW vw_OrderDetail AS
SELECT o.order_id, o.order_date, o.status,
       c.full_name AS customer_name, c.phone AS customer_phone,
       u.full_name AS staff_name,
       p.product_name, pv.size, pv.color, pv.sku,
       oi.quantity, oi.unit_price,
       oi.quantity * oi.unit_price AS line_total,
       o.discount_amount, o.total_amount,
       o.shipping_address
FROM Orders o
JOIN Customers c        ON o.customer_id  = c.customer_id
JOIN Users u            ON o.created_by   = u.user_id
JOIN OrderItems oi      ON oi.order_id    = o.order_id
JOIN ProductVariants pv ON oi.variant_id  = pv.variant_id
JOIN Products p         ON pv.product_id  = p.product_id;
GO

-- VIEW 8: Khách hàng mua nhiều nhất (VIP)
CREATE VIEW vw_TopCustomers AS
SELECT c.customer_id, c.full_name, c.email, c.phone, c.loyalty_points,
       COUNT(o.order_id)       AS total_orders,
       SUM(o.total_amount)     AS total_spent,
       MAX(o.order_date)       AS last_order_date,
       CASE
           WHEN SUM(o.total_amount) >= 5000000 THEN N'VIP Gold'
           WHEN SUM(o.total_amount) >= 2000000 THEN N'VIP Silver'
           ELSE N'Regular' END AS customer_tier
FROM Customers c
LEFT JOIN Orders o ON c.customer_id = o.customer_id AND o.status = 'delivered'
GROUP BY c.customer_id, c.full_name, c.email, c.phone, c.loyalty_points;
GO

-- VIEW 9: Phân quyền người dùng (user + role + permission)
CREATE VIEW vw_UserPermissions AS
SELECT u.user_id, u.full_name, u.email, u.is_active,
       r.role_name,
       p.module, p.action
FROM Users u
JOIN Roles r           ON u.role_id       = r.role_id
JOIN RolePermissions rp ON r.role_id      = rp.role_id
JOIN Permissions p     ON rp.permission_id = p.permission_id;
GO

-- VIEW 10: Thống kê nhập kho theo nhà cung cấp
CREATE VIEW vw_SupplierStockSummary AS
SELECT s.supplier_id, s.supplier_name, s.contact_person,
       COUNT(DISTINCT sr.receipt_id)       AS total_receipts,
       SUM(sri.quantity)                   AS total_items_received,
       SUM(sr.total_amount)                AS total_paid,
       MAX(sr.receipt_date)                AS last_receipt_date
FROM Suppliers s
LEFT JOIN StockReceipts sr     ON s.supplier_id = sr.supplier_id
LEFT JOIN StockReceiptItems sri ON sr.receipt_id = sri.receipt_id
GROUP BY s.supplier_id, s.supplier_name, s.contact_person;
GO

-- =====================================================
-- PHẦN 4: 10 STORED PROCEDURES
-- =====================================================

-- PROC 1: sp_CreateOrder → định nghĩa đầy đủ (XML + TRANSACTION) ở PATCH v3 bên dưới

-- PROC 2: Thêm sản phẩm vào đơn hàng & cập nhật total
CREATE PROCEDURE sp_AddOrderItem
    @order_id   INT,
    @variant_id INT,
    @quantity   INT
AS BEGIN
    SET NOCOUNT ON;
    DECLARE @unit_price DECIMAL(12,2);
    SELECT @unit_price = p.base_price + pv.extra_price
    FROM ProductVariants pv JOIN Products p ON pv.product_id = p.product_id
    WHERE pv.variant_id = @variant_id;

    INSERT INTO OrderItems (order_id, variant_id, quantity, unit_price)
    VALUES (@order_id, @variant_id, @quantity, @unit_price);

    UPDATE Orders
    SET total_amount = (SELECT SUM(quantity * unit_price) FROM OrderItems WHERE order_id = @order_id)
                      - discount_amount
    WHERE order_id = @order_id;
END
GO

-- PROC 3: Cập nhật trạng thái đơn hàng
CREATE PROCEDURE sp_UpdateOrderStatus
    @order_id  INT,
    @new_status NVARCHAR(30)
AS BEGIN
    SET NOCOUNT ON;
    IF @new_status NOT IN ('pending','confirmed','shipping','shipped','delivered','cancelled')
    BEGIN RAISERROR(N'Trạng thái không hợp lệ',16,1); RETURN; END
    UPDATE Orders SET status = @new_status WHERE order_id = @order_id;
END
GO

-- PROC 4: sp_ReceiveStock → định nghĩa đầy đủ (TRANSACTION) ở PATCH v3 bên dưới

-- PROC 5: Tìm kiếm sản phẩm theo tên / danh mục / thương hiệu
CREATE PROCEDURE sp_SearchProducts
    @keyword     NVARCHAR(100) = NULL,
    @category_id INT           = NULL,
    @brand_id    INT           = NULL,
    @min_price   DECIMAL(12,2) = NULL,
    @max_price   DECIMAL(12,2) = NULL
AS BEGIN
    SET NOCOUNT ON;
    SELECT p.product_id, p.product_name, b.brand_name, c.category_name,
           p.base_price, p.is_active
    FROM Products p
    JOIN Brands b    ON p.brand_id    = b.brand_id
    JOIN Categories c ON p.category_id = c.category_id
    WHERE (@keyword     IS NULL OR p.product_name LIKE N'%' + @keyword + '%')
      AND (@category_id IS NULL OR p.category_id  = @category_id)
      AND (@brand_id    IS NULL OR p.brand_id      = @brand_id)
      AND (@min_price   IS NULL OR p.base_price   >= @min_price)
      AND (@max_price   IS NULL OR p.base_price   <= @max_price)
      AND p.is_active = 1;
END
GO

-- PROC 6: Thống kê doanh thu theo khoảng thời gian
CREATE PROCEDURE sp_RevenueReport
    @from_date DATE,
    @to_date   DATE
AS BEGIN
    SET NOCOUNT ON;
    SELECT CAST(o.order_date AS DATE) AS sale_date,
           COUNT(o.order_id)          AS orders,
           SUM(o.total_amount)        AS revenue
    FROM Orders o
    WHERE CAST(o.order_date AS DATE) BETWEEN @from_date AND @to_date
      AND o.status = 'delivered'
    GROUP BY CAST(o.order_date AS DATE)
    ORDER BY sale_date;
END
GO

-- PROC 7: sp_DeductInventory → định nghĩa đầy đủ (set-based + TRANSACTION) ở PATCH v3 bên dưới

-- PROC 8: Cộng điểm loyalty cho khách hàng
CREATE PROCEDURE sp_AddLoyaltyPoints
    @customer_id INT,
    @order_id    INT
AS BEGIN
    SET NOCOUNT ON;
    DECLARE @total DECIMAL(14,2);
    SELECT @total = total_amount FROM Orders WHERE order_id = @order_id;
    DECLARE @points INT = CAST(@total / 10000 AS INT);  -- 1đ / 10.000đ
    UPDATE Customers SET loyalty_points += @points WHERE customer_id = @customer_id;
END
GO

-- PROC 9: Báo cáo tồn kho thấp theo kho
CREATE PROCEDURE sp_LowStockReport
    @warehouse_id INT = NULL
AS BEGIN
    SET NOCOUNT ON;
    SELECT p.product_name, pv.sku, pv.size, pv.color,
           w.warehouse_name, i.quantity, i.min_quantity,
           (i.min_quantity - i.quantity) AS need_to_restock
    FROM Inventory i
    JOIN ProductVariants pv ON i.variant_id   = pv.variant_id
    JOIN Products p         ON pv.product_id  = p.product_id
    JOIN Warehouses w       ON i.warehouse_id = w.warehouse_id
    WHERE i.quantity <= i.min_quantity
      AND (@warehouse_id IS NULL OR i.warehouse_id = @warehouse_id)
    ORDER BY need_to_restock DESC;
END
GO

-- PROC 10: Thêm sản phẩm mới kèm biến thể
CREATE PROCEDURE sp_AddProductWithVariants
    @category_id INT, @brand_id INT,
    @product_name NVARCHAR(200), @base_price DECIMAL(12,2),
    @description  NVARCHAR(MAX) = NULL,
    @new_product_id INT OUTPUT
AS BEGIN
    SET NOCOUNT ON;
    INSERT INTO Products (category_id, brand_id, product_name, base_price, description)
    VALUES (@category_id, @brand_id, @product_name, @base_price, @description);
    SET @new_product_id = SCOPE_IDENTITY();
END
GO

-- =====================================================
-- PHẦN 5: 10 FUNCTIONS
-- =====================================================

-- FUNC 1: Tính tổng tồn kho của 1 variant (tất cả kho)
CREATE FUNCTION fn_GetTotalStock(@variant_id INT)
RETURNS INT AS
BEGIN
    RETURN ISNULL((SELECT SUM(quantity) FROM Inventory WHERE variant_id = @variant_id), 0);
END
GO

-- FUNC 2: Tính giá bán thực tế của 1 variant
CREATE FUNCTION fn_GetVariantPrice(@variant_id INT)
RETURNS DECIMAL(12,2) AS
BEGIN
    DECLARE @price DECIMAL(12,2);
    SELECT @price = p.base_price + pv.extra_price
    FROM ProductVariants pv JOIN Products p ON pv.product_id = p.product_id
    WHERE pv.variant_id = @variant_id;
    RETURN ISNULL(@price, 0);
END
GO

-- FUNC 3: Tính tổng doanh thu của 1 khách hàng
CREATE FUNCTION fn_GetCustomerTotalSpent(@customer_id INT)
RETURNS DECIMAL(14,2) AS
BEGIN
    RETURN ISNULL((
        SELECT SUM(total_amount) FROM Orders
        WHERE customer_id = @customer_id AND status = 'delivered'
    ), 0);
END
GO

-- FUNC 4: Xếp loại khách hàng theo chi tiêu
CREATE FUNCTION fn_GetCustomerTier(@customer_id INT)
RETURNS NVARCHAR(20) AS
BEGIN
    DECLARE @spent DECIMAL(14,2) = dbo.fn_GetCustomerTotalSpent(@customer_id);
    RETURN CASE
        WHEN @spent >= 5000000  THEN N'VIP Gold'
        WHEN @spent >= 2000000  THEN N'VIP Silver'
        WHEN @spent >= 500000   THEN N'Regular'
        ELSE N'New'
    END;
END
GO

-- FUNC 5: Tính điểm loyalty tích lũy từ 1 đơn hàng
CREATE FUNCTION fn_CalcLoyaltyPoints(@order_amount DECIMAL(14,2))
RETURNS INT AS
BEGIN
    RETURN CAST(@order_amount / 10000 AS INT);
END
GO

-- FUNC 6: Kiểm tra còn hàng trong kho chỉ định
CREATE FUNCTION fn_IsInStock(@variant_id INT, @warehouse_id INT, @qty_needed INT)
RETURNS BIT AS
BEGIN
    DECLARE @stock INT;
    SELECT @stock = quantity FROM Inventory
    WHERE variant_id = @variant_id AND warehouse_id = @warehouse_id;
    RETURN CASE WHEN ISNULL(@stock,0) >= @qty_needed THEN 1 ELSE 0 END;
END
GO

-- FUNC 7: Lấy tên đầy đủ biến thể (product + size + màu)
CREATE FUNCTION fn_GetVariantFullName(@variant_id INT)
RETURNS NVARCHAR(300) AS
BEGIN
    DECLARE @name NVARCHAR(300);
    SELECT @name = p.product_name + N' - ' + ISNULL(pv.size,'') + N' / ' + ISNULL(pv.color,'')
    FROM ProductVariants pv JOIN Products p ON pv.product_id = p.product_id
    WHERE pv.variant_id = @variant_id;
    RETURN ISNULL(@name, N'Không tìm thấy');
END
GO

-- FUNC 8: Tính doanh thu theo tháng/năm
CREATE FUNCTION fn_GetMonthlyRevenue(@year INT, @month INT)
RETURNS DECIMAL(14,2) AS
BEGIN
    RETURN ISNULL((
        SELECT SUM(total_amount) FROM Orders
        WHERE YEAR(order_date) = @year AND MONTH(order_date) = @month
          AND status = 'delivered'
    ), 0);
END
GO

-- FUNC 9: Đếm số biến thể của 1 sản phẩm
CREATE FUNCTION fn_CountVariants(@product_id INT)
RETURNS INT AS
BEGIN
    RETURN ISNULL((SELECT COUNT(*) FROM ProductVariants WHERE product_id = @product_id), 0);
END
GO

-- FUNC 10: Format tiền VNĐ thành chuỗi
CREATE FUNCTION fn_FormatVND(@amount DECIMAL(14,2))
RETURNS NVARCHAR(50) AS
BEGIN
    RETURN FORMAT(@amount, N'#,##0') + N' đ';
END
GO

-- =====================================================
-- PHẦN 6: 10 TRIGGERS
-- =====================================================

-- TRIGGER 1: trg_DeductStockOnDelivered → định nghĩa đầy đủ ở PATCH v3 bên dưới

-- TRIGGER 2: Cộng điểm loyalty khi đơn hàng delivered
CREATE TRIGGER trg_AddLoyaltyOnDelivered
ON Orders AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE c SET c.loyalty_points += dbo.fn_CalcLoyaltyPoints(i.total_amount)
    FROM Customers c
    JOIN inserted i ON c.customer_id = i.customer_id
    JOIN deleted d  ON i.order_id    = d.order_id
    WHERE i.status = 'delivered' AND d.status <> 'delivered';
END
GO

-- TRIGGER 3: trg_UpdateStockOnReceipt → định nghĩa đầy đủ ở PATCH v3 bên dưới

-- TRIGGER 4: Ghi log khi xóa sản phẩm
CREATE TRIGGER trg_LogProductDelete
ON Products AFTER DELETE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO AuditLog (table_name, action, record_id, detail)
    SELECT 'Products', 'DELETE', product_id,
           N'Xóa sản phẩm: ' + product_name
    FROM deleted;
END
GO

-- TRIGGER 5: trg_PreventDeleteStockedProduct → định nghĩa đầy đủ ở PATCH v3 bên dưới

-- TRIGGER 6: Tự động cập nhật updated_at trong Inventory
CREATE TRIGGER trg_InventoryUpdatedAt
ON Inventory AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Inventory SET updated_at = GETDATE()
    WHERE inventory_id IN (SELECT inventory_id FROM inserted);
END
GO

-- TRIGGER 7: Ghi log khi thay đổi Role của User
CREATE TRIGGER trg_LogUserRoleChange
ON Users AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO AuditLog (table_name, action, record_id, detail)
    SELECT 'Users', 'UPDATE', i.user_id,
           N'Role thay đổi từ ' + CAST(d.role_id AS NVARCHAR) +
           N' → ' + CAST(i.role_id AS NVARCHAR)
    FROM inserted i JOIN deleted d ON i.user_id = d.user_id
    WHERE i.role_id <> d.role_id;
END
GO

-- TRIGGER 8: trg_PreventUpdateCancelledOrder → định nghĩa đầy đủ ở PATCH v3 bên dưới

-- TRIGGER 9: Tự cập nhật total_amount đơn hàng khi sửa OrderItems
-- [FIX] Xử lý đúng batch update (nhiều order_id cùng lúc) thay vì TOP 1
CREATE TRIGGER trg_RecalcOrderTotal
ON OrderItems AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    -- [FIX] Lấy tất cả order_id bị ảnh hưởng (không dùng TOP 1 để tránh bỏ sót)
    ;WITH affected AS (
        SELECT order_id FROM inserted
        UNION
        SELECT order_id FROM deleted
    )
    UPDATE o
    SET o.total_amount = ISNULL(
            (SELECT SUM(oi.quantity * oi.unit_price)
             FROM OrderItems oi WHERE oi.order_id = o.order_id), 0)
        - o.discount_amount
    FROM Orders o
    WHERE o.order_id IN (SELECT order_id FROM affected);
END
GO

-- TRIGGER 10: Ghi log mọi thay đổi giá sản phẩm
CREATE TRIGGER trg_LogPriceChange
ON Products AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO AuditLog (table_name, action, record_id, detail)
    SELECT 'Products', 'UPDATE', i.product_id,
           N'Giá thay đổi: ' + dbo.fn_FormatVND(d.base_price) +
           N' → ' + dbo.fn_FormatVND(i.base_price)
    FROM inserted i JOIN deleted d ON i.product_id = d.product_id
    WHERE i.base_price <> d.base_price;
END
GO

-- =====================================================
-- KIỂM TRA NHANH
-- =====================================================
PRINT N'';
PRINT N'✅ ĐÃ TẠO XONG DATABASE ClothingStoreDB';
PRINT N'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT N'📦 BẢNG: 14 bảng chính + 1 bảng AuditLog';
PRINT N'👁  VIEWS: 10 views';
PRINT N'⚙️  STORED PROCEDURES: 10 procedures';
PRINT N'🔧 FUNCTIONS: 10 functions';
PRINT N'🔔 TRIGGERS: 10 triggers';
PRINT N'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT N'-- Test nhanh:';
PRINT N'-- SELECT * FROM vw_InventoryByWarehouse';
PRINT N'-- SELECT * FROM vw_LowStockAlert';
PRINT N'-- SELECT * FROM vw_TopCustomers';
PRINT N'-- SELECT * FROM vw_OrderDetail';
PRINT N'-- SELECT dbo.fn_GetVariantFullName(1)';
PRINT N'-- SELECT dbo.fn_FormatVND(1500000)';
GO

-- =====================================================
-- PATCH v3 — CHỐt 10 ĐIỂM
-- Áp dụng SAU KHI chạy clothing_store_v2_complete.sql
-- Nội dung: DROP & RECREATE các Trigger + Procedure
--           đã được nâng cấp theo review giảng viên
-- =====================================================
USE ClothingStoreDB;
GO

-- =====================================================
-- PHẦN A: TRIGGERS NÂNG CẤP (có ROLLBACK + ACID)
-- =====================================================

-- ── TRIGGER 1 (nâng cấp): Trừ kho khi DELIVERED
--    Thêm kiểm tra tồn kho không âm → ROLLBACK nếu vi phạm
--    [FIX] Thêm kiểm tra is_stock_reserved để tránh double-deduct
-- ─────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS trg_DeductStockOnDelivered;
GO
CREATE TRIGGER trg_DeductStockOnDelivered
ON Orders AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ xử lý khi có đơn chuyển sang 'delivered'
    IF NOT EXISTS (
        SELECT 1 FROM inserted i JOIN deleted d ON i.order_id = d.order_id
        WHERE i.status = 'delivered' AND d.status <> 'delivered'
    ) RETURN;

    -- [FIX] Chỉ trừ kho nếu chưa reserve (is_stock_reserved = 0)
    --       Tránh double-deduct khi sp_CreateOrder đã RESERVE trước
    IF NOT EXISTS (
        SELECT 1 FROM inserted i JOIN deleted d ON i.order_id = d.order_id
        WHERE i.status = 'delivered' AND d.status <> 'delivered'
          AND i.is_stock_reserved = 0
    ) RETURN;   -- đã reserve rồi → không trừ nữa

    -- Kiểm tra tồn kho TRƯỚC khi trừ (chỉ áp dụng cho đơn chưa reserve)
    IF EXISTS (
        SELECT 1
        FROM Inventory inv
        JOIN OrderItems oi ON inv.variant_id = oi.variant_id
        JOIN inserted   i  ON oi.order_id    = i.order_id
        JOIN deleted    d  ON i.order_id     = d.order_id
        WHERE i.status = 'delivered' AND d.status <> 'delivered'
          AND i.is_stock_reserved = 0
          AND inv.warehouse_id = 1
          AND inv.quantity < oi.quantity   -- sẽ bị âm!
    )
    BEGIN
        RAISERROR(N'[TRIGGER] Tồn kho không đủ — không thể giao hàng. Giao dịch bị huỷ.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- An toàn → trừ kho
    UPDATE inv
    SET inv.quantity   -= oi.quantity,
        inv.updated_at  = GETDATE()
    FROM Inventory inv
    JOIN OrderItems oi ON inv.variant_id = oi.variant_id
    JOIN inserted   i  ON oi.order_id    = i.order_id
    JOIN deleted    d  ON i.order_id     = d.order_id
    WHERE i.status = 'delivered' AND d.status <> 'delivered'
      AND i.is_stock_reserved = 0
      AND inv.warehouse_id = 1;

    -- Ghi audit log
    INSERT INTO AuditLog (table_name, action, record_id, detail)
    SELECT 'Orders', 'STOCK_DEDUCT', i.order_id,
           N'Trừ kho thành công khi đơn ' + CAST(i.order_id AS NVARCHAR) + N' delivered'
    FROM inserted i JOIN deleted d ON i.order_id = d.order_id
    WHERE i.status = 'delivered' AND d.status <> 'delivered';
END
GO

-- ── TRIGGER 3 (nâng cấp): Nhập kho — kiểm tra quantity > 0
-- ─────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS trg_UpdateStockOnReceipt;
GO
CREATE TRIGGER trg_UpdateStockOnReceipt
ON StockReceiptItems AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Không cho nhập số lượng <= 0
    IF EXISTS (SELECT 1 FROM inserted WHERE quantity <= 0)
    BEGIN
        RAISERROR(N'[TRIGGER] Số lượng nhập kho phải lớn hơn 0. Giao dịch bị huỷ.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    MERGE Inventory AS tgt
    USING (
        SELECT sri.variant_id, sr.warehouse_id, SUM(sri.quantity) AS qty
        FROM inserted sri
        JOIN StockReceipts sr ON sri.receipt_id = sr.receipt_id
        GROUP BY sri.variant_id, sr.warehouse_id
    ) AS src
    ON tgt.variant_id = src.variant_id AND tgt.warehouse_id = src.warehouse_id
    WHEN MATCHED THEN
        UPDATE SET tgt.quantity += src.qty, tgt.updated_at = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (variant_id, warehouse_id, quantity, min_quantity)
        VALUES (src.variant_id, src.warehouse_id, src.qty, 5);
END
GO

-- ── TRIGGER 5 (nâng cấp): Ngăn xóa sản phẩm còn hàng
-- ──────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS trg_PreventDeleteStockedProduct;
GO
CREATE TRIGGER trg_PreventDeleteStockedProduct
ON Products INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM Inventory i
        JOIN ProductVariants pv ON i.variant_id  = pv.variant_id
        JOIN deleted d          ON pv.product_id = d.product_id
        WHERE i.quantity > 0
    )
    BEGIN
        RAISERROR(N'[TRIGGER] Không thể xóa sản phẩm còn tồn kho > 0. Vui lòng xuất hết hàng trước.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    DELETE FROM Products WHERE product_id IN (SELECT product_id FROM deleted);
    INSERT INTO AuditLog (table_name, action, record_id, detail)
    SELECT 'Products','DELETE', product_id, N'Xóa sản phẩm: ' + product_name FROM deleted;
END
GO

-- ── TRIGGER 8 (nâng cấp): Ngăn sửa đơn CANCELLED
-- ──────────────────────────────────────────────────
DROP TRIGGER IF EXISTS trg_PreventUpdateCancelledOrder;
GO
CREATE TRIGGER trg_PreventUpdateCancelledOrder
ON Orders INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM deleted WHERE status = 'cancelled')
    BEGIN
        RAISERROR(N'[TRIGGER] Đơn hàng đã HUỶ — không thể cập nhật. Giao dịch bị huỷ.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    UPDATE o SET
        o.status            = i.status,
        o.shipping_address  = i.shipping_address,
        o.discount_amount   = i.discount_amount,
        o.total_amount      = i.total_amount,
        o.note              = i.note
    FROM Orders o JOIN inserted i ON o.order_id = i.order_id;
END
GO

-- ── TRIGGER MỚI: Ngăn tồn kho bị âm khi UPDATE trực tiếp
-- ─────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS trg_PreventNegativeInventory;
GO
CREATE TRIGGER trg_PreventNegativeInventory
ON Inventory AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted WHERE quantity < 0)
    BEGIN
        RAISERROR(N'[TRIGGER] Vi phạm ràng buộc ACID: tồn kho không được âm. Giao dịch bị huỷ.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

-- =====================================================
-- PHẦN B: STORED PROCEDURES NÂNG CẤP (có TRANSACTION)
-- =====================================================

-- ── PROC 1 (nâng cấp): Tạo đơn hàng — FULL TRANSACTION
--    BEGIN TRAN → insert order → insert items → update stock → COMMIT/ROLLBACK
-- ──────────────────────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_CreateOrder;
GO
CREATE PROCEDURE sp_CreateOrder
    @customer_id      INT,
    @created_by       INT,
    @shipping_address NVARCHAR(300),
    @discount_amount  DECIMAL(12,2) = 0,
    @note             NVARCHAR(300) = NULL,
    -- Truyền danh sách variant dưới dạng XML: <items><i vid="1" qty="2"/></items>
    @items_xml        XML,
    @new_order_id     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @new_order_id = NULL;

    BEGIN TRANSACTION;
    BEGIN TRY

        -- Bước 1: Tạo đơn hàng (total = 0, sẽ tính sau)
        INSERT INTO Orders (customer_id, created_by, shipping_address, discount_amount, total_amount, note)
        VALUES (@customer_id, @created_by, @shipping_address, @discount_amount, 0, @note);
        SET @new_order_id = SCOPE_IDENTITY();

        -- Bước 2: Parse XML → thêm từng OrderItem
        INSERT INTO OrderItems (order_id, variant_id, quantity, unit_price)
        SELECT @new_order_id,
               x.item.value('@vid', 'INT'),
               x.item.value('@qty', 'INT'),
               dbo.fn_GetVariantPrice(x.item.value('@vid', 'INT'))
        FROM @items_xml.nodes('/items/i') AS x(item);

        -- Bước 3: Kiểm tra tồn kho (kho mặc định = 1)
        IF EXISTS (
            SELECT 1
            FROM OrderItems oi
            JOIN Inventory inv ON oi.variant_id   = inv.variant_id
                               AND inv.warehouse_id = 1
            WHERE oi.order_id = @new_order_id
              AND inv.quantity < oi.quantity
        )
        BEGIN
            RAISERROR(N'[sp_CreateOrder] Không đủ tồn kho cho một hoặc nhiều sản phẩm.', 16, 1);
            -- sẽ nhảy vào CATCH → ROLLBACK
        END

        -- Bước 4: Cập nhật total_amount
        UPDATE Orders
        SET total_amount = (
                SELECT SUM(quantity * unit_price) FROM OrderItems WHERE order_id = @new_order_id
            ) - @discount_amount
        WHERE order_id = @new_order_id;

        -- Bước 5: Trừ tồn kho ngay (RESERVE stock khi tạo đơn = giữ hàng)
        UPDATE inv
        SET inv.quantity -= oi.quantity, inv.updated_at = GETDATE()
        FROM Inventory inv
        JOIN OrderItems oi ON inv.variant_id = oi.variant_id
        WHERE oi.order_id = @new_order_id AND inv.warehouse_id = 1;

        -- [FIX] Đánh dấu đã reserve stock → trigger trg_DeductStockOnDelivered
        --       sẽ bỏ qua đơn này, tránh double-deduct
        UPDATE Orders SET is_stock_reserved = 1 WHERE order_id = @new_order_id;

        -- Bước 6: Ghi audit log
        INSERT INTO AuditLog (table_name, action, record_id, detail)
        VALUES ('Orders', 'INSERT', @new_order_id,
                N'Tạo đơn hàng thành công cho customer ' + CAST(@customer_id AS NVARCHAR));

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SET @new_order_id = NULL;
        -- Ném lại lỗi để caller xử lý
        DECLARE @msg  NVARCHAR(2048) = ERROR_MESSAGE();
        DECLARE @sev  INT            = ERROR_SEVERITY();
        DECLARE @st   INT            = ERROR_STATE();
        RAISERROR(@msg, @sev, @st);
    END CATCH
END
GO

-- ── PROC 7 (nâng cấp): Xuất kho — FULL TRANSACTION + ROLLBACK
-- ─────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_DeductInventory;
GO
CREATE PROCEDURE sp_DeductInventory
    @order_id     INT,
    @warehouse_id INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY

        -- Kiểm tra tổng thể trước
        IF EXISTS (
            SELECT 1
            FROM OrderItems oi
            LEFT JOIN Inventory inv
                ON oi.variant_id = inv.variant_id AND inv.warehouse_id = @warehouse_id
            WHERE oi.order_id = @order_id
              AND ISNULL(inv.quantity, 0) < oi.quantity
        )
        BEGIN
            RAISERROR(N'[sp_DeductInventory] Không đủ tồn kho. Toàn bộ xuất kho bị huỷ (ROLLBACK).', 16, 1);
        END

        UPDATE inv
        SET inv.quantity -= oi.quantity, inv.updated_at = GETDATE()
        FROM Inventory inv
        JOIN OrderItems oi ON inv.variant_id   = oi.variant_id
                           AND inv.warehouse_id = @warehouse_id
        WHERE oi.order_id = @order_id;

        -- Double-check sau UPDATE
        IF EXISTS (SELECT 1 FROM Inventory WHERE warehouse_id = @warehouse_id AND quantity < 0)
        BEGIN
            RAISERROR(N'[sp_DeductInventory] Phát hiện tồn kho âm sau khi trừ — ROLLBACK.', 16, 1);
        END

        INSERT INTO AuditLog (table_name, action, record_id, detail)
        VALUES ('Inventory','DEDUCT', @order_id,
                N'Xuất kho thành công cho đơn ' + CAST(@order_id AS NVARCHAR));

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @msg NVARCHAR(2048) = ERROR_MESSAGE();
        RAISERROR(@msg, 16, 1);
    END CATCH
END
GO

-- ── PROC 4 (nâng cấp): Nhập kho — FULL TRANSACTION
-- ───────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_ReceiveStock;
GO
CREATE PROCEDURE sp_ReceiveStock
    @supplier_id  INT,
    @warehouse_id INT,
    @created_by   INT,
    @variant_id   INT,
    @quantity     INT,
    @unit_cost    DECIMAL(12,2),
    @note         NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @quantity <= 0
    BEGIN
        RAISERROR(N'[sp_ReceiveStock] Số lượng nhập phải > 0.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;
    BEGIN TRY

        DECLARE @receipt_id INT;
        INSERT INTO StockReceipts (supplier_id, warehouse_id, created_by, total_amount, note)
        VALUES (@supplier_id, @warehouse_id, @created_by, @quantity * @unit_cost, @note);
        SET @receipt_id = SCOPE_IDENTITY();

        -- Trigger trg_UpdateStockOnReceipt sẽ tự cập nhật Inventory
        INSERT INTO StockReceiptItems (receipt_id, variant_id, quantity, unit_cost)
        VALUES (@receipt_id, @variant_id, @quantity, @unit_cost);

        INSERT INTO AuditLog (table_name, action, record_id, detail)
        VALUES ('StockReceipts','INSERT', @receipt_id,
                N'Nhập ' + CAST(@quantity AS NVARCHAR) + N' units variant ' +
                CAST(@variant_id AS NVARCHAR) + N' vào kho ' + CAST(@warehouse_id AS NVARCHAR));

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @msg NVARCHAR(2048) = ERROR_MESSAGE();
        RAISERROR(@msg, 16, 1);
    END CATCH
END
GO

-- =====================================================
-- PHẦN C: DEMO SCRIPT (chạy để test)
-- =====================================================

PRINT N'';
PRINT N'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT N'  DEMO SCRIPT — dán vào SSMS để kiểm tra từng case';
PRINT N'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT N'';
PRINT N'-- [1] Tạo đơn hàng mới với TRANSACTION đầy đủ:';
PRINT N'DECLARE @oid INT;';
PRINT N'EXEC sp_CreateOrder';
PRINT N'    @customer_id = 1, @created_by = 3,';
PRINT N'    @shipping_address = N''Q1 TP.HCM'',';
PRINT N'    @items_xml = ''<items><i vid="1" qty="2"/><i vid="9" qty="1"/></items>'',';
PRINT N'    @new_order_id = @oid OUTPUT;';
PRINT N'SELECT @oid AS new_order_id;';
PRINT N'';
PRINT N'-- [2] Thử trigger ROLLBACK khi tồn kho âm:';
PRINT N'UPDATE Inventory SET quantity = 1 WHERE variant_id = 1 AND warehouse_id = 1;';
PRINT N'UPDATE Orders SET status = ''delivered'' WHERE order_id = 1;';
PRINT N'-- → Sẽ báo lỗi và ROLLBACK vì kho chỉ còn 1, đơn cần 2';
PRINT N'';
PRINT N'-- [3] Kiểm tra tồn kho thấp:';
PRINT N'SELECT * FROM vw_LowStockAlert ORDER BY shortage DESC;';
PRINT N'';
PRINT N'-- [4] Xem audit log:';
PRINT N'SELECT * FROM AuditLog ORDER BY changed_at DESC;';
PRINT N'';
PRINT N'-- [5] Doanh thu tháng:';
PRINT N'SELECT * FROM vw_MonthlyRevenue ORDER BY yr, mo;';
PRINT N'';
PRINT N'-- [6] Top khách hàng:';
PRINT N'SELECT * FROM vw_TopCustomers ORDER BY total_spent DESC;';
PRINT N'';
PRINT N'-- [7] Function format VNĐ:';
PRINT N'SELECT dbo.fn_FormatVND(1500000);   -- → 1.500.000 đ';
PRINT N'SELECT dbo.fn_GetVariantFullName(1); -- → tên đầy đủ';
PRINT N'SELECT dbo.fn_GetCustomerTier(4);   -- → VIP Gold / Silver';
GO

PRINT N'';
PRINT N'✅ PATCH v3 ÁP DỤNG THÀNH CÔNG!';
PRINT N'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT N'  Triggers có ROLLBACK + ACID  ✔';
PRINT N'  sp_CreateOrder có TRANSACTION  ✔';
PRINT N'  sp_DeductInventory có ROLLBACK  ✔';
PRINT N'  sp_ReceiveStock có TRANSACTION  ✔';
PRINT N'  trg_PreventNegativeInventory mới  ✔';
PRINT N'  Demo script sẵn sàng chạy  ✔';
PRINT N'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
GO
import { useState, useEffect, useRef } from "react";

// ─── DESIGN TOKENS ────────────────────────────────────────────
const T = {
  sb: "#0c0c18",
  sbBorder: "rgba(255,255,255,0.07)",
  gold: "#c8a84b",
  goldL: "#fdf6e3",
  goldD: "#8b6914",
  bg: "#f4f3ef",
  card: "#ffffff",
  border: "#e8e4db",
  txt: "#1a1917",
  muted: "#706d62",
  faint: "#a8a49a",
  success: "#059669",
  successL: "#d1fae5",
  successD: "#065f46",
  warning: "#d97706",
  warningL: "#fef3c7",
  warningD: "#92400e",
  info: "#2563eb",
  infoL: "#dbeafe",
  infoD: "#1e40af",
  danger: "#dc2626",
  dangerL: "#fee2e2",
  dangerD: "#991b1b",
};

// ─── SEED DATA ────────────────────────────────────────────────
const ROLES = ["Admin", "Manager", "Sales Staff", "Warehouse Staff", "Viewer"];
const GENDERS = ["Nam", "Nữ", "Khác"];
const ORDER_STATUSES = [
  "pending",
  "confirmed",
  "shipping",
  "shipped",
  "delivered",
  "cancelled",
];
const PAY_METHODS = ["Tiền mặt", "Chuyển khoản", "Momo", "VNPay", "Thẻ"];
const CATEGORIES = [
  "Áo thun",
  "Áo sơ mi",
  "Áo khoác",
  "Áo hoodie",
  "Quần jean",
  "Quần kaki",
  "Quần short",
  "Váy ngắn",
  "Đầm dài",
  "Mũ & Nón",
  "Thắt lưng",
];

const initStaff = [
  {
    id: 1,
    role: "Admin",
    name: "THTrang",
    email: "admin@store.vn",
    phone: "0901000001",
    active: true,
    created: "10/01/2023",
  },
  {
    id: 2,
    role: "Manager",
    name: " Manager",
    email: "manager@store.vn",
    phone: "0901000002",
    active: true,
    created: "10/01/2023",
  },
  {
    id: 3,
    role: "Sales Staff",
    name: "Sales 1",
    email: "sales1@store.vn",
    phone: "0901000003",
    active: true,
    created: "15/01/2023",
  },
  {
    id: 4,
    role: "Sales Staff",
    name: "Sales 2",
    email: "sales2@store.vn",
    phone: "0901000004",
    active: true,
    created: "15/01/2023",
  },
  {
    id: 5,
    role: "Sales Staff",
    name: "Sales 3",
    email: "sales3@store.vn",
    phone: "0901000006",
    active: true,
    created: "20/01/2023",
  },
  {
    id: 6,
    role: "Warehouse Staff",
    name: "Warehouse",
    email: "warehouse@store.vn",
    phone: "0901000005",
    active: true,
    created: "20/01/2023",
  },
  {
    id: 7,
    role: "Viewer",
    name: "Viewer",
    email: "viewer@store.vn",
    phone: "0901000007",
    active: false,
    created: "01/02/2023",
  },
];

const initCustomers = [
  {
    id: 1,
    name: "Nguyễn Thị Hoa",
    email: "hoa@gmail.com",
    phone: "0901111001",
    city: "TP.HCM",
    gender: "Nữ",
    birthday: "1995-03-12",
    points: 250,
    spent: 1280000,
    orders: 2,
    created: "10/01/2024",
  },
  {
    id: 2,
    name: "Trần Văn Bình",
    email: "binh@gmail.com",
    phone: "0901111002",
    city: "Hà Nội",
    gender: "Nam",
    birthday: "1992-07-20",
    points: 180,
    spent: 1480000,
    orders: 2,
    created: "10/01/2024",
  },
  {
    id: 3,
    name: "Lê Thị Mai",
    email: "mai@gmail.com",
    phone: "0901111003",
    city: "Đà Nẵng",
    gender: "Nữ",
    birthday: "1998-11-05",
    points: 90,
    spent: 830000,
    orders: 2,
    created: "15/01/2024",
  },
  {
    id: 4,
    name: "Phạm Quốc Hùng",
    email: "hung@gmail.com",
    phone: "0901111004",
    city: "TP.HCM",
    gender: "Nam",
    birthday: "1990-01-15",
    points: 320,
    spent: 2090000,
    orders: 2,
    created: "15/01/2024",
  },
  {
    id: 5,
    name: "Hoàng Thị Linh",
    email: "linh@gmail.com",
    phone: "0901111005",
    city: "Hà Nội",
    gender: "Nữ",
    birthday: "1997-05-22",
    points: 75,
    spent: 1780000,
    orders: 2,
    created: "20/01/2024",
  },
  {
    id: 6,
    name: "Vũ Minh Khôi",
    email: "khoi@gmail.com",
    phone: "0901111006",
    city: "TP.HCM",
    gender: "Nam",
    birthday: "1993-09-30",
    points: 410,
    spent: 770000,
    orders: 1,
    created: "20/01/2024",
  },
  {
    id: 7,
    name: "Đặng Thị Yến",
    email: "yen@gmail.com",
    phone: "0901111007",
    city: "Đà Nẵng",
    gender: "Nữ",
    birthday: "1999-02-14",
    points: 60,
    spent: 590000,
    orders: 1,
    created: "01/02/2024",
  },
  {
    id: 8,
    name: "Bùi Văn Đức",
    email: "duc@gmail.com",
    phone: "0901111008",
    city: "Hà Nội",
    gender: "Nam",
    birthday: "1988-12-03",
    points: 200,
    spent: 1940000,
    orders: 2,
    created: "01/02/2024",
  },
  {
    id: 9,
    name: "Ngô Thị Thanh",
    email: "thanh@gmail.com",
    phone: "0901111009",
    city: "TP.HCM",
    gender: "Nữ",
    birthday: "1996-06-18",
    points: 130,
    spent: 415000,
    orders: 1,
    created: "05/02/2024",
  },
  {
    id: 10,
    name: "Dương Văn Tùng",
    email: "tung@gmail.com",
    phone: "0901111010",
    city: "TP.HCM",
    gender: "Nam",
    birthday: "1994-04-07",
    points: 290,
    spent: 1510000,
    orders: 2,
    created: "05/02/2024",
  },
  {
    id: 11,
    name: "Phan Thị Ngọc",
    email: "ngoc@gmail.com",
    phone: "0901111011",
    city: "Đà Nẵng",
    gender: "Nữ",
    birthday: "2000-08-25",
    points: 45,
    spent: 280000,
    orders: 1,
    created: "10/02/2024",
  },
  {
    id: 12,
    name: "Tô Văn Hải",
    email: "hai@gmail.com",
    phone: "0901111012",
    city: "Hà Nội",
    gender: "Nam",
    birthday: "1991-10-11",
    points: 160,
    spent: 1050000,
    orders: 1,
    created: "10/02/2024",
  },
];

const initOrders = [
  {
    id: "DH-001",
    cid: 1,
    cname: "Nguyễn Thị Hoa",
    date: "15/01/2024",
    status: "delivered",
    total: 520000,
    discount: 0,
    method: "Tiền mặt",
    note: "",
    staff: "Lê Văn Sales 1",
  },
  {
    id: "DH-002",
    cid: 2,
    cname: "Trần Văn Bình",
    date: "18/01/2024",
    status: "delivered",
    total: 830000,
    discount: 50000,
    method: "Chuyển khoản",
    note: "Khách VIP",
    staff: "Lê Văn Sales 1",
  },
  {
    id: "DH-003",
    cid: 3,
    cname: "Lê Thị Mai",
    date: "02/02/2024",
    status: "delivered",
    total: 450000,
    discount: 0,
    method: "Momo",
    note: "",
    staff: "Phạm Thị Sales 2",
  },
  {
    id: "DH-004",
    cid: 4,
    cname: "Phạm Quốc Hùng",
    date: "10/02/2024",
    status: "delivered",
    total: 1200000,
    discount: 0,
    method: "VNPay",
    note: "Giao nhanh",
    staff: "Lê Văn Sales 1",
  },
  {
    id: "DH-005",
    cid: 5,
    cname: "Hoàng Thị Linh",
    date: "20/02/2024",
    status: "delivered",
    total: 680000,
    discount: 100000,
    method: "Tiền mặt",
    note: "",
    staff: "Phạm Thị Sales 2",
  },
  {
    id: "DH-006",
    cid: 6,
    cname: "Vũ Minh Khôi",
    date: "05/03/2024",
    status: "delivered",
    total: 350000,
    discount: 0,
    method: "Chuyển khoản",
    note: "",
    staff: "Lê Văn Sales 1",
  },
  {
    id: "DH-007",
    cid: 7,
    cname: "Đặng Thị Yến",
    date: "12/03/2024",
    status: "delivered",
    total: 590000,
    discount: 0,
    method: "Momo",
    note: "",
    staff: "Ngô Thị Sales 3",
  },
  {
    id: "DH-008",
    cid: 8,
    cname: "Bùi Văn Đức",
    date: "22/03/2024",
    status: "delivered",
    total: 960000,
    discount: 0,
    method: "Thẻ",
    note: "",
    staff: "Lê Văn Sales 1",
  },
  {
    id: "DH-009",
    cid: 9,
    cname: "Ngô Thị Thanh",
    date: "01/04/2024",
    status: "delivered",
    total: 415000,
    discount: 50000,
    method: "Tiền mặt",
    note: "",
    staff: "Phạm Thị Sales 2",
  },
  {
    id: "DH-010",
    cid: 10,
    cname: "Dương Văn Tùng",
    date: "08/04/2024",
    status: "delivered",
    total: 780000,
    discount: 0,
    method: "VNPay",
    note: "",
    staff: "Ngô Thị Sales 3",
  },
  {
    id: "DH-011",
    cid: 11,
    cname: "Phan Thị Ngọc",
    date: "15/04/2024",
    status: "cancelled",
    total: 280000,
    discount: 0,
    method: "Tiền mặt",
    note: "Khách hủy",
    staff: "Lê Văn Sales 1",
  },
  {
    id: "DH-012",
    cid: 12,
    cname: "Tô Văn Hải",
    date: "02/05/2024",
    status: "delivered",
    total: 1050000,
    discount: 0,
    method: "Chuyển khoản",
    note: "",
    staff: "Phạm Thị Sales 2",
  },
  {
    id: "DH-016",
    cid: 1,
    cname: "Nguyễn Thị Hoa",
    date: "12/06/2024",
    status: "shipped",
    total: 870000,
    discount: 0,
    method: "VNPay",
    note: "",
    staff: "Ngô Thị Sales 3",
  },
  {
    id: "DH-017",
    cid: 3,
    cname: "Lê Thị Mai",
    date: "20/06/2024",
    status: "confirmed",
    total: 540000,
    discount: 0,
    method: "Momo",
    note: "",
    staff: "Lê Văn Sales 1",
  },
  {
    id: "DH-018",
    cid: 5,
    cname: "Hoàng Thị Linh",
    date: "01/07/2024",
    status: "pending",
    total: 690000,
    discount: 0,
    method: "Chuyển khoản",
    note: "",
    staff: "Phạm Thị Sales 2",
  },
  {
    id: "DH-019",
    cid: 9,
    cname: "Ngô Thị Thanh",
    date: "08/07/2024",
    status: "shipped",
    total: 950000,
    discount: 50000,
    method: "Thẻ",
    note: "",
    staff: "Ngô Thị Sales 3",
  },
];

const initProducts = [
  {
    id: 1,
    name: "Áo thun nam basic trắng",
    cat: "Áo thun",
    brand: "Local Brand VN",
    price: 150000,
    stock: 240,
    active: true,
  },
  {
    id: 2,
    name: "Áo thun nam basic đen",
    cat: "Áo thun",
    brand: "Local Brand VN",
    price: 150000,
    stock: 185,
    active: true,
  },
  {
    id: 5,
    name: "Áo thun UrbanFit oversize",
    cat: "Áo thun",
    brand: "UrbanFit",
    price: 220000,
    stock: 210,
    active: true,
  },
  {
    id: 9,
    name: "Áo thun StreetStyle tie-dye",
    cat: "Áo thun",
    brand: "StreetStyle Co",
    price: 230000,
    stock: 96,
    active: true,
  },
  {
    id: 15,
    name: "Áo thun NightOwl in hình",
    cat: "Áo thun",
    brand: "NightOwl Apparel",
    price: 240000,
    stock: 42,
    active: true,
  },
  {
    id: 21,
    name: "Áo sơ mi nam trắng",
    cat: "Áo sơ mi",
    brand: "Local Brand VN",
    price: 280000,
    stock: 162,
    active: true,
  },
  {
    id: 26,
    name: "Áo sơ mi denim",
    cat: "Áo sơ mi",
    brand: "StreetStyle Co",
    price: 400000,
    stock: 88,
    active: true,
  },
  {
    id: 33,
    name: "Áo khoác bomber basic",
    cat: "Áo khoác",
    brand: "Local Brand VN",
    price: 450000,
    stock: 145,
    active: true,
  },
  {
    id: 37,
    name: "Áo khoác blazer",
    cat: "Áo khoác",
    brand: "PureBasic",
    price: 720000,
    stock: 68,
    active: true,
  },
  {
    id: 45,
    name: "Hoodie basic không mũ",
    cat: "Áo hoodie",
    brand: "Local Brand VN",
    price: 320000,
    stock: 195,
    active: true,
  },
  {
    id: 52,
    name: "Hoodie zip-up",
    cat: "Áo hoodie",
    brand: "NightOwl Apparel",
    price: 420000,
    stock: 34,
    active: false,
  },
  {
    id: 55,
    name: "Quần jean slim xanh nhạt",
    cat: "Quần jean",
    brand: "Local Brand VN",
    price: 420000,
    stock: 220,
    active: true,
  },
  {
    id: 61,
    name: "Quần jean wide leg",
    cat: "Quần jean",
    brand: "UrbanFit",
    price: 480000,
    stock: 112,
    active: true,
  },
  {
    id: 70,
    name: "Quần kaki slim be",
    cat: "Quần kaki",
    brand: "Local Brand VN",
    price: 350000,
    stock: 112,
    active: true,
  },
  {
    id: 88,
    name: "Váy ngắn hoa nhí",
    cat: "Váy ngắn",
    brand: "Local Brand VN",
    price: 280000,
    stock: 88,
    active: true,
  },
  {
    id: 98,
    name: "Đầm dài hoa mùa hè",
    cat: "Đầm dài",
    brand: "Local Brand VN",
    price: 380000,
    stock: 75,
    active: true,
  },
];

// ─── HELPERS ──────────────────────────────────────────────────
const fmt = (n) => n?.toLocaleString("vi-VN") + " ₫";
const fmtM = (n) =>
  n >= 1e6 ? (n / 1e6).toFixed(1) + "tr₫" : n?.toLocaleString("vi-VN") + "₫";
const uid = () => Math.random().toString(36).slice(2, 8).toUpperCase();
const today = () => new Date().toLocaleDateString("vi-VN");

const ROLE_COLORS = {
  Admin: { bg: "#f3e8ff", c: "#6b21a8" },
  Manager: { bg: "#dbeafe", c: "#1d4ed8" },
  "Sales Staff": { bg: "#d1fae5", c: "#065f46" },
  "Warehouse Staff": { bg: "#fef3c7", c: "#92400e" },
  Viewer: { bg: "#f3f4f6", c: "#374151" },
};
const STATUS_META = {
  pending: { label: "Chờ xử lý", bg: "#f3f4f6", c: "#374151", dot: "#9ca3af" },
  confirmed: { label: "Đã duyệt", bg: "#fef3c7", c: "#92400e", dot: "#f59e0b" },
  shipping: { label: "Đang ship", bg: "#ede9fe", c: "#5b21b6", dot: "#8b5cf6" },
  shipped: { label: "Đang giao", bg: "#dbeafe", c: "#1e40af", dot: "#3b82f6" },
  delivered: { label: "Đã giao", bg: "#d1fae5", c: "#065f46", dot: "#059669" },
  cancelled: { label: "Đã hủy", bg: "#fee2e2", c: "#991b1b", dot: "#ef4444" },
};

// ─── UI ATOMS ─────────────────────────────────────────────────
const Dot = ({ c, size = 7 }) => (
  <span
    style={{
      display: "inline-block",
      width: size,
      height: size,
      borderRadius: "50%",
      background: c,
      marginRight: 5,
      flexShrink: 0,
    }}
  />
);

function Badge({ label, bg, c }) {
  return (
    <span
      style={{
        display: "inline-flex",
        alignItems: "center",
        padding: "3px 10px",
        borderRadius: 20,
        background: bg,
        color: c,
        fontSize: 12,
        fontWeight: 500,
        whiteSpace: "nowrap",
      }}
    >
      {label}
    </span>
  );
}

function StatusBadge({ status }) {
  const m = STATUS_META[status] || STATUS_META.pending;
  return (
    <span
      style={{
        display: "inline-flex",
        alignItems: "center",
        padding: "3px 10px",
        borderRadius: 20,
        background: m.bg,
        color: m.c,
        fontSize: 12,
        fontWeight: 500,
      }}
    >
      <Dot c={m.dot} />
      {m.label}
    </span>
  );
}

function TierBadge({ spent }) {
  if (spent >= 2e6) return <Badge label="★ Gold" bg="#fef9c3" c="#854d0e" />;
  if (spent >= 1e6) return <Badge label="◆ Silver" bg="#f1f5f9" c="#334155" />;
  return <Badge label="Regular" bg={T.bg} c={T.muted} />;
}

function Avatar({ name, size = 32, gold = false }) {
  const ini = name
    .split(" ")
    .slice(-2)
    .map((w) => w[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: "50%",
        background: gold ? T.gold : `${T.gold}28`,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontSize: size > 36 ? 14 : 11,
        fontWeight: 700,
        color: gold ? "#0c0c18" : T.goldD,
        flexShrink: 0,
      }}
    >
      {ini}
    </div>
  );
}

function Btn({
  children,
  onClick,
  variant = "ghost",
  size = "md",
  danger = false,
  disabled = false,
  icon,
}) {
  const pad = size === "sm" ? "5px 12px" : "8px 18px";
  const fs = size === "sm" ? 12 : 13;
  const base = {
    display: "inline-flex",
    alignItems: "center",
    gap: 5,
    cursor: disabled ? "not-allowed" : "pointer",
    padding: pad,
    borderRadius: 8,
    fontSize: fs,
    fontWeight: 500,
    transition: "all .15s",
    border: "none",
    userSelect: "none",
    opacity: disabled ? 0.5 : 1,
  };
  const styles = {
    primary: { background: T.gold, color: "#0c0c18" },
    ghost: {
      background: "transparent",
      color: danger ? T.danger : T.muted,
      border: `1px solid ${T.border}`,
    },
    danger: { background: T.dangerL, color: T.danger },
  };
  return (
    <button
      style={{ ...base, ...styles[variant] }}
      onClick={disabled ? undefined : onClick}
    >
      {icon}
      {children}
    </button>
  );
}

function Input({
  label,
  value,
  onChange,
  type = "text",
  placeholder = "",
  required = false,
  options,
}) {
  const s = {
    width: "100%",
    padding: "8px 11px",
    borderRadius: 7,
    border: `1px solid ${T.border}`,
    fontSize: 13,
    color: T.txt,
    background: T.card,
    outline: "none",
    boxSizing: "border-box",
  };
  return (
    <div style={{ marginBottom: 14 }}>
      {label && (
        <div
          style={{
            fontSize: 12,
            fontWeight: 500,
            color: T.muted,
            marginBottom: 5,
          }}
        >
          {label}
          {required && <span style={{ color: T.danger }}> *</span>}
        </div>
      )}
      {options ? (
        <select
          value={value}
          onChange={(e) => onChange(e.target.value)}
          style={s}
        >
          {options.map((o) => (
            <option key={o} value={o}>
              {o}
            </option>
          ))}
        </select>
      ) : (
        <input
          type={type}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          style={s}
        />
      )}
    </div>
  );
}

// ─── MODAL ────────────────────────────────────────────────────
function Modal({ title, onClose, children, width = 480 }) {
  useEffect(() => {
    const esc = (e) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", esc);
    return () => window.removeEventListener("keydown", esc);
  }, [onClose]);
  return (
    <div
      onClick={onClose}
      style={{
        position: "fixed",
        inset: 0,
        background: "rgba(0,0,0,0.45)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        zIndex: 1000,
        padding: 20,
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: T.card,
          borderRadius: 14,
          width: "100%",
          maxWidth: width,
          maxHeight: "90vh",
          overflowY: "auto",
          boxShadow: "0 20px 60px rgba(0,0,0,0.2)",
        }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            padding: "18px 24px",
            borderBottom: `1px solid ${T.border}`,
          }}
        >
          <div style={{ fontSize: 15, fontWeight: 700, color: T.txt }}>
            {title}
          </div>
          <button
            onClick={onClose}
            style={{
              background: "none",
              border: "none",
              cursor: "pointer",
              fontSize: 20,
              color: T.muted,
              lineHeight: 1,
              padding: "0 4px",
            }}
          >
            ×
          </button>
        </div>
        <div style={{ padding: "20px 24px" }}>{children}</div>
      </div>
    </div>
  );
}

function ConfirmModal({ msg, onConfirm, onClose }) {
  return (
    <Modal title="Xác nhận" onClose={onClose} width={380}>
      <p style={{ fontSize: 14, color: T.txt, marginBottom: 20 }}>{msg}</p>
      <div style={{ display: "flex", gap: 10, justifyContent: "flex-end" }}>
        <Btn onClick={onClose}>Hủy</Btn>
        <Btn onClick={onConfirm} variant="danger">
          Xóa
        </Btn>
      </div>
    </Modal>
  );
}

function Toast({ msg, type = "success", onDone }) {
  useEffect(() => {
    const t = setTimeout(onDone, 2400);
    return () => clearTimeout(t);
  }, [onDone]);
  const bg =
    type === "success"
      ? T.successL
      : type === "danger"
      ? T.dangerL
      : T.warningL;
  const c =
    type === "success"
      ? T.successD
      : type === "danger"
      ? T.dangerD
      : T.warningD;
  return (
    <div
      style={{
        position: "fixed",
        bottom: 28,
        right: 28,
        zIndex: 9999,
        background: bg,
        color: c,
        padding: "12px 20px",
        borderRadius: 10,
        fontSize: 13,
        fontWeight: 500,
        boxShadow: "0 4px 20px rgba(0,0,0,0.12)",
        animation: "slideUp .25s ease",
      }}
    >
      {type === "success" ? "✓ " : type === "danger" ? "✕ " : "⚠ "}
      {msg}
    </div>
  );
}

// ─── LAYOUT ATOMS ─────────────────────────────────────────────
function PageShell({ title, subtitle, action, children }) {
  return (
    <div style={{ padding: "28px 32px", maxWidth: 1120, minHeight: "100vh" }}>
      <div
        style={{
          display: "flex",
          alignItems: "flex-start",
          justifyContent: "space-between",
          marginBottom: 24,
          gap: 16,
        }}
      >
        <div>
          <h1
            style={{
              fontSize: 21,
              fontWeight: 800,
              color: T.txt,
              margin: 0,
              letterSpacing: "-0.3px",
            }}
          >
            {title}
          </h1>
          {subtitle && (
            <p style={{ fontSize: 13, color: T.muted, margin: "4px 0 0" }}>
              {subtitle}
            </p>
          )}
        </div>
        {action}
      </div>
      {children}
    </div>
  );
}

function KpiCard({ label, value, sub, color = "#059669", icon }) {
  return (
    <div
      style={{
        background: T.card,
        border: `1px solid ${T.border}`,
        borderRadius: 12,
        padding: "18px 20px",
      }}
    >
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: 10,
        }}
      >
        <span style={{ fontSize: 12, fontWeight: 500, color: T.muted }}>
          {label}
        </span>
        {icon && <span style={{ fontSize: 18 }}>{icon}</span>}
      </div>
      <div
        style={{
          fontSize: 26,
          fontWeight: 800,
          color: T.txt,
          letterSpacing: "-0.5px",
          marginBottom: 4,
        }}
      >
        {value}
      </div>
      {sub && <div style={{ fontSize: 12, color: T.muted }}>{sub}</div>}
    </div>
  );
}

function Table({ cols, rows }) {
  return (
    <div
      style={{
        background: T.card,
        border: `1px solid ${T.border}`,
        borderRadius: 12,
        overflow: "hidden",
      }}
    >
      <table
        style={{ width: "100%", borderCollapse: "collapse", fontSize: 13 }}
      >
        <thead>
          <tr
            style={{
              background: "#fafaf8",
              borderBottom: `1px solid ${T.border}`,
            }}
          >
            {cols.map((c) => (
              <th
                key={c}
                style={{
                  padding: "10px 16px",
                  textAlign: "left",
                  fontWeight: 500,
                  color: T.muted,
                  whiteSpace: "nowrap",
                }}
              >
                {c}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.length ? (
            rows
          ) : (
            <tr>
              <td
                colSpan={cols.length}
                style={{ padding: "48px", textAlign: "center", color: T.faint }}
              >
                Không có dữ liệu
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

function TR({ children, onClick }) {
  const [hover, setHover] = useState(false);
  return (
    <tr
      onClick={onClick}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        borderBottom: `1px solid ${T.border}`,
        background: hover && onClick ? "#fafaf8" : "transparent",
        cursor: onClick ? "pointer" : "default",
        transition: "background .1s",
      }}
    >
      {children}
    </tr>
  );
}
const TD = ({ children, right, mono, muted, bold }) => (
  <td
    style={{
      padding: "11px 16px",
      textAlign: right ? "right" : "left",
      fontFamily: mono ? "monospace" : "inherit",
      fontSize: mono ? 12 : 13,
      color: muted ? T.muted : T.txt,
      fontWeight: bold ? 700 : 400,
    }}
  >
    {children}
  </td>
);

function SearchBar({ value, onChange }) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 8,
        background: T.card,
        border: `1px solid ${T.border}`,
        borderRadius: 8,
        padding: "7px 12px",
        minWidth: 220,
      }}
    >
      <span style={{ fontSize: 14, color: T.muted }}>🔍</span>
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder="Tìm kiếm..."
        style={{
          border: "none",
          outline: "none",
          fontSize: 13,
          background: "transparent",
          color: T.txt,
          width: "100%",
        }}
      />
    </div>
  );
}

function FilterBtns({ options, value, onChange, getLabel, colorFn }) {
  return (
    <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
      {options.map((o) => {
        const active = value === o;
        const col = colorFn ? colorFn(o) : null;
        return (
          <button
            key={o}
            onClick={() => onChange(o)}
            style={{
              padding: "5px 13px",
              borderRadius: 20,
              cursor: "pointer",
              fontSize: 12,
              fontWeight: active ? 600 : 400,
              border: `1px solid ${active ? T.gold : T.border}`,
              background: active ? T.goldL : "transparent",
              color: active ? T.goldD : T.muted,
              transition: "all .12s",
            }}
          >
            {getLabel ? getLabel(o) : o}
          </button>
        );
      })}
    </div>
  );
}

// ─── PAGES ────────────────────────────────────────────────────

// Dashboard
function Dashboard({ staff, customers, orders, products }) {
  const delivered = orders.filter((o) => o.status === "delivered");
  const revenue = delivered.reduce((s, o) => s + o.total, 0);
  const pending = orders.filter((o) =>
    ["pending", "confirmed"].includes(o.status)
  ).length;
  const lowStock = products.filter((p) => p.stock < 50).length;
  const monthly = [
    { m: "T1", r: 1350000 },
    { m: "T2", r: 3010000 },
    { m: "T3", r: 1900000 },
    { m: "T4", r: 1195000 },
    { m: "T5", r: 2860000 },
    { m: "T6", r: 1190000 },
    { m: "T7", r: 2820000 },
    { m: "T8", r: 2670000 },
    { m: "T9", r: 2620000 },
  ];
  const maxR = Math.max(...monthly.map((m) => m.r));
  return (
    <PageShell
      title="Tổng quan"
      subtitle="ClothingStoreDB · Hệ thống quản lý bán quần áo"
    >
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(4,1fr)",
          gap: 14,
          marginBottom: 24,
        }}
      >
        <KpiCard
          label="Doanh thu (đã giao)"
          value={fmtM(revenue)}
          sub={`${delivered.length} đơn hoàn thành`}
        />
        <KpiCard
          label="Tổng đơn hàng"
          value={orders.length}
          sub={`${pending} đang chờ xử lý`}
        />
        <KpiCard
          label="Nhân viên"
          value={staff.filter((s) => s.active).length}
          sub={`${staff.length} tổng cộng`}
        />
        <KpiCard
          label="Tồn kho thấp"
          value={lowStock}
          sub="sản phẩm < 50 units"
        />
      </div>
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "1fr 1fr",
          gap: 16,
          marginBottom: 16,
        }}
      >
        <div
          style={{
            background: T.card,
            border: `1px solid ${T.border}`,
            borderRadius: 12,
            padding: "20px 22px",
          }}
        >
          <div
            style={{
              fontSize: 13,
              fontWeight: 600,
              color: T.txt,
              marginBottom: 16,
            }}
          >
            Doanh thu theo tháng
          </div>
          <div
            style={{
              display: "flex",
              alignItems: "flex-end",
              gap: 6,
              height: 130,
            }}
          >
            {monthly.map((m) => {
              const h = Math.max(6, Math.round((m.r / maxR) * 110));
              return (
                <div
                  key={m.m}
                  style={{
                    flex: 1,
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    gap: 3,
                  }}
                >
                  <div style={{ fontSize: 9, color: T.muted }}>
                    {(m.r / 1e6).toFixed(1)}
                  </div>
                  <div
                    style={{
                      width: "100%",
                      height: h,
                      background: T.gold,
                      borderRadius: "3px 3px 0 0",
                      opacity: 0.85,
                    }}
                  />
                  <div style={{ fontSize: 10, color: T.muted }}>{m.m}</div>
                </div>
              );
            })}
          </div>
        </div>
        <div
          style={{
            background: T.card,
            border: `1px solid ${T.border}`,
            borderRadius: 12,
            padding: "20px 22px",
          }}
        >
          <div
            style={{
              fontSize: 13,
              fontWeight: 600,
              color: T.txt,
              marginBottom: 14,
            }}
          >
            Trạng thái đơn hàng
          </div>
          {Object.entries(STATUS_META).map(([k, m]) => {
            const cnt = orders.filter((o) => o.status === k).length;
            const pct = orders.length
              ? Math.round((cnt / orders.length) * 100)
              : 0;
            return (
              <div key={k} style={{ marginBottom: 9 }}>
                <div
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    marginBottom: 3,
                  }}
                >
                  <span style={{ fontSize: 12, color: T.txt }}>{m.label}</span>
                  <span style={{ fontSize: 12, fontWeight: 700, color: T.txt }}>
                    {cnt}
                  </span>
                </div>
                <div style={{ height: 4, background: T.bg, borderRadius: 2 }}>
                  <div
                    style={{
                      height: "100%",
                      width: `${pct}%`,
                      background: m.dot,
                      borderRadius: 2,
                    }}
                  />
                </div>
              </div>
            );
          })}
        </div>
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
        <div
          style={{
            background: T.card,
            border: `1px solid ${T.border}`,
            borderRadius: 12,
            overflow: "hidden",
          }}
        >
          <div
            style={{
              padding: "14px 18px",
              borderBottom: `1px solid ${T.border}`,
              fontSize: 13,
              fontWeight: 600,
              color: T.txt,
            }}
          >
            Đơn hàng gần đây
          </div>
          <table
            style={{ width: "100%", borderCollapse: "collapse", fontSize: 12 }}
          >
            {orders.slice(0, 6).map((o) => (
              <tr key={o.id} style={{ borderBottom: `1px solid ${T.border}` }}>
                <td
                  style={{
                    padding: "9px 18px",
                    fontFamily: "monospace",
                    color: T.goldD,
                    fontWeight: 700,
                  }}
                >
                  {o.id}
                </td>
                <td style={{ padding: "9px 8px", color: T.txt }}>{o.cname}</td>
                <td style={{ padding: "9px 8px" }}>
                  <StatusBadge status={o.status} />
                </td>
                <td
                  style={{
                    padding: "9px 18px",
                    fontWeight: 700,
                    textAlign: "right",
                    color: T.txt,
                  }}
                >
                  {fmtM(o.total)}
                </td>
              </tr>
            ))}
          </table>
        </div>
        <div
          style={{
            background: T.card,
            border: `1px solid ${T.border}`,
            borderRadius: 12,
            overflow: "hidden",
          }}
        >
          <div
            style={{
              padding: "14px 18px",
              borderBottom: `1px solid ${T.border}`,
              fontSize: 13,
              fontWeight: 600,
              color: T.txt,
            }}
          >
            Khách hàng VIP
          </div>
          {[...customers]
            .sort((a, b) => b.spent - a.spent)
            .slice(0, 6)
            .map((c) => (
              <div
                key={c.id}
                style={{
                  padding: "10px 18px",
                  borderBottom: `1px solid ${T.border}`,
                  display: "flex",
                  alignItems: "center",
                  gap: 10,
                }}
              >
                <Avatar name={c.name} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div
                    style={{
                      fontSize: 13,
                      fontWeight: 500,
                      color: T.txt,
                      whiteSpace: "nowrap",
                      overflow: "hidden",
                      textOverflow: "ellipsis",
                    }}
                  >
                    {c.name}
                  </div>
                  <div style={{ fontSize: 11, color: T.muted }}>{c.city}</div>
                </div>
                <div style={{ textAlign: "right" }}>
                  <div style={{ fontSize: 13, fontWeight: 700, color: T.txt }}>
                    {fmtM(c.spent)}
                  </div>
                  <TierBadge spent={c.spent} />
                </div>
              </div>
            ))}
        </div>
      </div>
    </PageShell>
  );
}

// Staff
function StaffPage({ staff, setStaff, toast }) {
  const [search, setSearch] = useState("");
  const [roleF, setRoleF] = useState("Tất cả");
  const [modal, setModal] = useState(null); // null | {mode:"add"|"edit"|"view", data}
  const [confirm, setConfirm] = useState(null);
  const empty = {
    name: "",
    email: "",
    phone: "",
    role: "Sales Staff",
    active: true,
  };
  const [form, setForm] = useState(empty);
  const [err, setErr] = useState({});

  const roles = ["Tất cả", ...ROLES];
  const shown = staff.filter((s) => {
    const q = search.toLowerCase();
    const ok =
      !q ||
      s.name.toLowerCase().includes(q) ||
      s.email.toLowerCase().includes(q);
    const okR = roleF === "Tất cả" || s.role === roleF;
    return ok && okR;
  });

  const openAdd = () => {
    setForm(empty);
    setErr({});
    setModal({ mode: "add" });
  };
  const openEdit = (s) => {
    setForm({ ...s });
    setErr({});
    setModal({ mode: "edit", data: s });
  };
  const openView = (s) => setModal({ mode: "view", data: s });

  const validate = () => {
    const e = {};
    if (!form.name.trim()) e.name = "Bắt buộc";
    if (!form.email.includes("@")) e.email = "Email không hợp lệ";
    if (form.phone && !/^0\d{9}$/.test(form.phone))
      e.phone = "10 chữ số, bắt đầu 0";
    setErr(e);
    return !Object.keys(e).length;
  };

  const save = () => {
    if (!validate()) return;
    if (modal.mode === "add") {
      setStaff((prev) => [
        ...prev,
        { ...form, id: Date.now(), created: today() },
      ]);
      toast("Thêm nhân viên thành công");
    } else {
      setStaff((prev) =>
        prev.map((s) => (s.id === modal.data.id ? { ...s, ...form } : s))
      );
      toast("Cập nhật thành công");
    }
    setModal(null);
  };

  const del = (id) => {
    setStaff((prev) => prev.filter((s) => s.id !== id));
    setConfirm(null);
    toast("Đã xóa nhân viên", "danger");
  };

  const toggleActive = (id) => {
    setStaff((prev) =>
      prev.map((s) => (s.id === id ? { ...s, active: !s.active } : s))
    );
    toast("Đã cập nhật trạng thái");
  };

  const ErrMsg = ({ f }) =>
    err[f] ? (
      <div
        style={{
          fontSize: 11,
          color: T.danger,
          marginTop: -10,
          marginBottom: 8,
        }}
      >
        {err[f]}
      </div>
    ) : null;

  return (
    <PageShell
      title="Nhân viên"
      subtitle={`${staff.length} nhân viên · ${
        staff.filter((s) => s.active).length
      } đang hoạt động`}
      action={
        <Btn variant="primary" onClick={openAdd} icon="＋">
          Thêm nhân viên
        </Btn>
      }
    >
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(5,1fr)",
          gap: 12,
          marginBottom: 20,
        }}
      >
        {ROLES.map((r) => {
          const cnt = staff.filter((s) => s.role === r).length;
          const col = ROLE_COLORS[r];
          return (
            <div
              key={r}
              style={{
                background: T.card,
                border: `1px solid ${T.border}`,
                borderRadius: 10,
                padding: "14px 16px",
              }}
            >
              <div style={{ fontSize: 11, color: T.muted, marginBottom: 4 }}>
                {r}
              </div>
              <div style={{ fontSize: 22, fontWeight: 800, color: T.txt }}>
                {cnt}
              </div>
              <div style={{ marginTop: 6 }}>
                <span
                  style={{
                    padding: "2px 8px",
                    borderRadius: 20,
                    fontSize: 11,
                    background: col.bg,
                    color: col.c,
                  }}
                >
                  nhân viên
                </span>
              </div>
            </div>
          );
        })}
      </div>

      <div
        style={{ display: "flex", gap: 10, marginBottom: 14, flexWrap: "wrap" }}
      >
        <SearchBar value={search} onChange={setSearch} />
        <FilterBtns options={roles} value={roleF} onChange={setRoleF} />
      </div>

      <Table
        cols={[
          "Nhân viên",
          "Vai trò",
          "Email",
          "Điện thoại",
          "Trạng thái",
          "Ngày tạo",
          "Thao tác",
        ]}
        rows={shown.map((s) => (
          <TR key={s.id} onClick={() => openView(s)}>
            <TD>
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <Avatar name={s.name} />
                <span style={{ fontWeight: 500 }}>{s.name}</span>
              </div>
            </TD>
            <TD>
              <Badge label={s.role} {...ROLE_COLORS[s.role]} />
            </TD>
            <TD muted>{s.email}</TD>
            <TD muted>{s.phone}</TD>
            <TD>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  toggleActive(s.id);
                }}
                style={{
                  padding: "3px 10px",
                  borderRadius: 20,
                  fontSize: 12,
                  cursor: "pointer",
                  border: "none",
                  fontWeight: 500,
                  background: s.active ? T.successL : T.dangerL,
                  color: s.active ? T.successD : T.dangerD,
                }}
              >
                {s.active ? "● Hoạt động" : "○ Tạm nghỉ"}
              </button>
            </TD>
            <TD muted>{s.created}</TD>
            <TD>
              <div
                style={{ display: "flex", gap: 6 }}
                onClick={(e) => e.stopPropagation()}
              >
                <Btn size="sm" onClick={() => openEdit(s)}>
                  Sửa
                </Btn>
                <Btn size="sm" danger onClick={() => setConfirm(s.id)}>
                  Xóa
                </Btn>
              </div>
            </TD>
          </TR>
        ))}
      />

      {modal &&
        (modal.mode === "view" ? (
          <Modal title="Thông tin nhân viên" onClose={() => setModal(null)}>
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: 16,
                marginBottom: 20,
                padding: "0 0 16px",
                borderBottom: `1px solid ${T.border}`,
              }}
            >
              <Avatar name={modal.data.name} size={52} gold />
              <div>
                <div style={{ fontSize: 18, fontWeight: 700, color: T.txt }}>
                  {modal.data.name}
                </div>
                <Badge
                  label={modal.data.role}
                  {...ROLE_COLORS[modal.data.role]}
                />
              </div>
            </div>
            {[
              ["Email", modal.data.email],
              ["Điện thoại", modal.data.phone],
              ["Ngày tạo", modal.data.created],
            ].map(([k, v]) => (
              <div
                key={k}
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  padding: "8px 0",
                  borderBottom: `1px solid ${T.border}`,
                }}
              >
                <span style={{ fontSize: 13, color: T.muted }}>{k}</span>
                <span style={{ fontSize: 13, fontWeight: 500, color: T.txt }}>
                  {v || "—"}
                </span>
              </div>
            ))}
            <div
              style={{
                marginTop: 16,
                display: "flex",
                justifyContent: "flex-end",
                gap: 8,
              }}
            >
              <Btn
                onClick={() => {
                  setModal(null);
                  openEdit(modal.data);
                }}
              >
                Chỉnh sửa
              </Btn>
              <Btn onClick={() => setModal(null)} variant="primary">
                Đóng
              </Btn>
            </div>
          </Modal>
        ) : (
          <Modal
            title={
              modal.mode === "add" ? "Thêm nhân viên" : "Chỉnh sửa nhân viên"
            }
            onClose={() => setModal(null)}
          >
            <Input
              label="Họ và tên"
              value={form.name}
              onChange={(v) => setForm((f) => ({ ...f, name: v }))}
              required
            />
            <ErrMsg f="name" />
            <Input
              label="Email"
              type="email"
              value={form.email}
              onChange={(v) => setForm((f) => ({ ...f, email: v }))}
              required
            />
            <ErrMsg f="email" />
            <Input
              label="Điện thoại"
              value={form.phone}
              onChange={(v) => setForm((f) => ({ ...f, phone: v }))}
              placeholder="0901234567"
            />
            <ErrMsg f="phone" />
            <Input
              label="Vai trò"
              value={form.role}
              onChange={(v) => setForm((f) => ({ ...f, role: v }))}
              options={ROLES}
            />
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: 10,
                marginBottom: 16,
              }}
            >
              <input
                type="checkbox"
                checked={form.active}
                onChange={(e) =>
                  setForm((f) => ({ ...f, active: e.target.checked }))
                }
                id="activeChk"
              />
              <label htmlFor="activeChk" style={{ fontSize: 13, color: T.txt }}>
                Đang hoạt động
              </label>
            </div>
            <div
              style={{ display: "flex", gap: 10, justifyContent: "flex-end" }}
            >
              <Btn onClick={() => setModal(null)}>Hủy</Btn>
              <Btn variant="primary" onClick={save}>
                {modal.mode === "add" ? "Thêm" : "Lưu thay đổi"}
              </Btn>
            </div>
          </Modal>
        ))}
      {confirm && (
        <ConfirmModal
          msg="Xóa nhân viên này?"
          onConfirm={() => del(confirm)}
          onClose={() => setConfirm(null)}
        />
      )}
    </PageShell>
  );
}

// Customers
function CustomersPage({ customers, setCustomers, toast }) {
  const [search, setSearch] = useState("");
  const [tierF, setTierF] = useState("Tất cả");
  const [modal, setModal] = useState(null);
  const [confirm, setConfirm] = useState(null);
  const empty = {
    name: "",
    email: "",
    phone: "",
    city: "",
    gender: "Nữ",
    birthday: "",
    points: 0,
    note: "",
  };
  const [form, setForm] = useState(empty);
  const [err, setErr] = useState({});

  const getTier = (spent) =>
    spent >= 2e6 ? "Gold" : spent >= 1e6 ? "Silver" : "Regular";
  const tiers = ["Tất cả", "Gold", "Silver", "Regular"];

  const shown = customers.filter((c) => {
    const q = search.toLowerCase();
    const ok =
      !q ||
      c.name.toLowerCase().includes(q) ||
      c.phone?.includes(q) ||
      c.email?.toLowerCase().includes(q);
    const t = getTier(c.spent);
    const okT = tierF === "Tất cả" || t === tierF;
    return ok && okT;
  });

  const openAdd = () => {
    setForm(empty);
    setErr({});
    setModal({ mode: "add" });
  };
  const openEdit = (c) => {
    setForm({ ...c });
    setErr({});
    setModal({ mode: "edit", data: c });
  };
  const openView = (c) => setModal({ mode: "view", data: c });

  const validate = () => {
    const e = {};
    if (!form.name.trim()) e.name = "Bắt buộc";
    if (form.email && !form.email.includes("@")) e.email = "Email không hợp lệ";
    setErr(e);
    return !Object.keys(e).length;
  };

  const save = () => {
    if (!validate()) return;
    if (modal.mode === "add") {
      setCustomers((prev) => [
        ...prev,
        { ...form, id: Date.now(), spent: 0, orders: 0, created: today() },
      ]);
      toast("Thêm khách hàng thành công");
    } else {
      setCustomers((prev) =>
        prev.map((c) => (c.id === modal.data.id ? { ...c, ...form } : c))
      );
      toast("Cập nhật thành công");
    }
    setModal(null);
  };

  const del = (id) => {
    setCustomers((prev) => prev.filter((c) => c.id !== id));
    setConfirm(null);
    toast("Đã xóa", "danger");
  };
  const ErrMsg = ({ f }) =>
    err[f] ? (
      <div
        style={{
          fontSize: 11,
          color: T.danger,
          marginTop: -10,
          marginBottom: 8,
        }}
      >
        {err[f]}
      </div>
    ) : null;

  return (
    <PageShell
      title="Khách hàng"
      subtitle={`${customers.length} khách hàng · ${
        customers.filter((c) => c.spent >= 2e6).length
      } Gold · ${
        customers.filter((c) => c.spent >= 1e6 && c.spent < 2e6).length
      } Silver`}
      action={
        <Btn variant="primary" onClick={openAdd} icon="＋">
          Thêm khách hàng
        </Btn>
      }
    >
      <div
        style={{ display: "flex", gap: 10, marginBottom: 14, flexWrap: "wrap" }}
      >
        <SearchBar value={search} onChange={setSearch} />
        <FilterBtns options={tiers} value={tierF} onChange={setTierF} />
      </div>

      <Table
        cols={[
          "Khách hàng",
          "Điện thoại",
          "Khu vực",
          "Đơn hàng",
          "Chi tiêu",
          "Điểm",
          "Hạng",
          "Thao tác",
        ]}
        rows={[...shown]
          .sort((a, b) => b.spent - a.spent)
          .map((c) => (
            <TR key={c.id} onClick={() => openView(c)}>
              <TD>
                <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <Avatar name={c.name} />
                  <span style={{ fontWeight: 500 }}>{c.name}</span>
                </div>
              </TD>
              <TD muted>{c.phone}</TD>
              <TD muted>{c.city}</TD>
              <TD>
                <span style={{ fontWeight: 700 }}>{c.orders}</span>
              </TD>
              <TD bold>{fmtM(c.spent)}</TD>
              <TD>
                <span style={{ color: T.goldD, fontWeight: 700 }}>
                  {c.points}
                </span>
              </TD>
              <TD>
                <TierBadge spent={c.spent} />
              </TD>
              <TD>
                <div
                  style={{ display: "flex", gap: 6 }}
                  onClick={(e) => e.stopPropagation()}
                >
                  <Btn size="sm" onClick={() => openEdit(c)}>
                    Sửa
                  </Btn>
                  <Btn size="sm" danger onClick={() => setConfirm(c.id)}>
                    Xóa
                  </Btn>
                </div>
              </TD>
            </TR>
          ))}
      />

      {modal &&
        (modal.mode === "view" ? (
          <Modal title="Thông tin khách hàng" onClose={() => setModal(null)}>
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: 16,
                marginBottom: 20,
                padding: "0 0 16px",
                borderBottom: `1px solid ${T.border}`,
              }}
            >
              <Avatar name={modal.data.name} size={52} gold />
              <div>
                <div style={{ fontSize: 18, fontWeight: 700 }}>
                  {modal.data.name}
                </div>
                <TierBadge spent={modal.data.spent} />
              </div>
            </div>
            {[
              ["Email", modal.data.email],
              ["Điện thoại", modal.data.phone],
              ["Khu vực", modal.data.city],
              ["Giới tính", modal.data.gender],
              ["Sinh nhật", modal.data.birthday],
              ["Tổng đơn", modal.data.orders + " đơn"],
              ["Tổng chi tiêu", fmt(modal.data.spent)],
              ["Điểm tích lũy", modal.data.points + " điểm"],
              ["Ngày đăng ký", modal.data.created],
            ].map(([k, v]) => (
              <div
                key={k}
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  padding: "8px 0",
                  borderBottom: `1px solid ${T.border}`,
                }}
              >
                <span style={{ fontSize: 13, color: T.muted }}>{k}</span>
                <span style={{ fontSize: 13, fontWeight: 500 }}>
                  {v || "—"}
                </span>
              </div>
            ))}
            <div
              style={{
                marginTop: 16,
                display: "flex",
                justifyContent: "flex-end",
                gap: 8,
              }}
            >
              <Btn
                onClick={() => {
                  setModal(null);
                  openEdit(modal.data);
                }}
              >
                Chỉnh sửa
              </Btn>
              <Btn onClick={() => setModal(null)} variant="primary">
                Đóng
              </Btn>
            </div>
          </Modal>
        ) : (
          <Modal
            title={
              modal.mode === "add" ? "Thêm khách hàng" : "Chỉnh sửa khách hàng"
            }
            onClose={() => setModal(null)}
          >
            <Input
              label="Họ và tên"
              value={form.name}
              onChange={(v) => setForm((f) => ({ ...f, name: v }))}
              required
            />
            <ErrMsg f="name" />
            <Input
              label="Email"
              type="email"
              value={form.email || ""}
              onChange={(v) => setForm((f) => ({ ...f, email: v }))}
            />
            <ErrMsg f="email" />
            <Input
              label="Điện thoại"
              value={form.phone || ""}
              onChange={(v) => setForm((f) => ({ ...f, phone: v }))}
            />
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "1fr 1fr",
                gap: 12,
              }}
            >
              <Input
                label="Khu vực"
                value={form.city || ""}
                onChange={(v) => setForm((f) => ({ ...f, city: v }))}
                placeholder="TP.HCM"
              />
              <Input
                label="Giới tính"
                value={form.gender || "Nữ"}
                onChange={(v) => setForm((f) => ({ ...f, gender: v }))}
                options={GENDERS}
              />
            </div>
            <Input
              label="Ngày sinh"
              type="date"
              value={form.birthday || ""}
              onChange={(v) => setForm((f) => ({ ...f, birthday: v }))}
            />
            {modal.mode === "edit" && (
              <Input
                label="Điểm tích lũy"
                type="number"
                value={String(form.points || 0)}
                onChange={(v) =>
                  setForm((f) => ({ ...f, points: parseInt(v) || 0 }))
                }
              />
            )}
            <div
              style={{ display: "flex", gap: 10, justifyContent: "flex-end" }}
            >
              <Btn onClick={() => setModal(null)}>Hủy</Btn>
              <Btn variant="primary" onClick={save}>
                {modal.mode === "add" ? "Thêm" : "Lưu thay đổi"}
              </Btn>
            </div>
          </Modal>
        ))}
      {confirm && (
        <ConfirmModal
          msg="Xóa khách hàng này?"
          onConfirm={() => del(confirm)}
          onClose={() => setConfirm(null)}
        />
      )}
    </PageShell>
  );
}

// Orders
function OrdersPage({ orders, setOrders, customers, toast }) {
  const [search, setSearch] = useState("");
  const [statusF, setStatusF] = useState("Tất cả");
  const [modal, setModal] = useState(null);
  const [confirm, setConfirm] = useState(null);
  const empty = {
    cname: "",
    total: 0,
    discount: 0,
    status: "pending",
    method: "Tiền mặt",
    note: "",
  };
  const [form, setForm] = useState(empty);

  const statusOptions = ["Tất cả", ...ORDER_STATUSES];
  const shown = orders.filter((o) => {
    const q = search.toLowerCase();
    const ok =
      !q || o.cname.toLowerCase().includes(q) || o.id.toLowerCase().includes(q);
    const okS = statusF === "Tất cả" || o.status === statusF;
    return ok && okS;
  });

  const openAdd = () => {
    setForm(empty);
    setModal({ mode: "add" });
  };
  const openEdit = (o) => {
    setForm({ ...o });
    setModal({ mode: "edit", data: o });
  };
  const openView = (o) => setModal({ mode: "view", data: o });

  const save = () => {
    if (!form.cname.trim() || form.total <= 0) return;
    if (modal.mode === "add") {
      setOrders((prev) => [
        ...prev,
        {
          ...form,
          id: "DH-" + uid(),
          date: today(),
          staff: "Lê Văn Sales 1",
          cid: 0,
        },
      ]);
      toast("Tạo đơn hàng thành công");
    } else {
      setOrders((prev) =>
        prev.map((o) => (o.id === modal.data.id ? { ...o, ...form } : o))
      );
      toast("Cập nhật đơn hàng");
    }
    setModal(null);
  };

  const del = (id) => {
    setOrders((prev) => prev.filter((o) => o.id !== id));
    setConfirm(null);
    toast("Đã xóa đơn", "danger");
  };

  const changeStatus = (id, st) => {
    setOrders((prev) =>
      prev.map((o) => (o.id === id ? { ...o, status: st } : o))
    );
    toast("Cập nhật trạng thái thành công");
  };

  const StatusDropdown = ({ order }) => {
    const [open, setOpen] = useState(false);
    const ref = useRef(null);
    useEffect(() => {
      const fn = (e) => {
        if (ref.current && !ref.current.contains(e.target)) setOpen(false);
      };
      document.addEventListener("mousedown", fn);
      return () => document.removeEventListener("mousedown", fn);
    }, []);
    return (
      <div
        ref={ref}
        style={{ position: "relative" }}
        onClick={(e) => e.stopPropagation()}
      >
        <div onClick={() => setOpen((v) => !v)} style={{ cursor: "pointer" }}>
          <StatusBadge status={order.status} />
        </div>
        {open && (
          <div
            style={{
              position: "absolute",
              top: "calc(100% + 4px)",
              left: 0,
              zIndex: 500,
              background: T.card,
              border: `1px solid ${T.border}`,
              borderRadius: 8,
              overflow: "hidden",
              minWidth: 130,
              boxShadow: "0 4px 20px rgba(0,0,0,0.1)",
            }}
          >
            {ORDER_STATUSES.map((s) => {
              const m = STATUS_META[s];
              return (
                <div
                  key={s}
                  onClick={() => {
                    changeStatus(order.id, s);
                    setOpen(false);
                  }}
                  style={{
                    padding: "8px 14px",
                    cursor: "pointer",
                    fontSize: 12,
                    display: "flex",
                    alignItems: "center",
                    gap: 7,
                    background: order.status === s ? T.bg : "transparent",
                    fontWeight: order.status === s ? 600 : 400,
                    color: T.txt,
                  }}
                >
                  <Dot c={m.dot} />
                  {m.label}
                </div>
              );
            })}
          </div>
        )}
      </div>
    );
  };

  const totalRev = shown
    .filter((o) => o.status === "delivered")
    .reduce((s, o) => s + o.total, 0);

  return (
    <PageShell
      title="Đơn hàng"
      subtitle={`${orders.length} đơn · doanh thu đã giao ${fmtM(
        orders
          .filter((o) => o.status === "delivered")
          .reduce((s, o) => s + o.total, 0)
      )}`}
      action={
        <Btn variant="primary" onClick={openAdd} icon="＋">
          Tạo đơn hàng
        </Btn>
      }
    >
      <div
        style={{
          display: "flex",
          gap: 10,
          marginBottom: 14,
          flexWrap: "wrap",
          alignItems: "center",
        }}
      >
        <SearchBar value={search} onChange={setSearch} />
        <FilterBtns
          options={statusOptions}
          value={statusF}
          onChange={setStatusF}
          getLabel={(o) => (o === "Tất cả" ? o : STATUS_META[o]?.label)}
        />
        {shown.length > 0 && (
          <span style={{ fontSize: 12, color: T.muted, marginLeft: "auto" }}>
            {shown.length} đơn · {fmtM(totalRev)}
          </span>
        )}
      </div>

      <Table
        cols={[
          "Mã đơn",
          "Khách hàng",
          "Ngày đặt",
          "Phương thức",
          "Trạng thái",
          "Tổng tiền",
          "Thao tác",
        ]}
        rows={shown.map((o) => (
          <TR key={o.id} onClick={() => openView(o)}>
            <TD mono>
              <span style={{ color: T.goldD, fontWeight: 700 }}>{o.id}</span>
            </TD>
            <TD bold>{o.cname}</TD>
            <TD muted>{o.date}</TD>
            <TD muted>{o.method}</TD>
            <TD>
              <StatusDropdown order={o} />
            </TD>
            <TD right bold>
              {fmtM(o.total)}
            </TD>
            <TD>
              <div
                style={{ display: "flex", gap: 6 }}
                onClick={(e) => e.stopPropagation()}
              >
                <Btn size="sm" onClick={() => openEdit(o)}>
                  Sửa
                </Btn>
                <Btn size="sm" danger onClick={() => setConfirm(o.id)}>
                  Xóa
                </Btn>
              </div>
            </TD>
          </TR>
        ))}
      />

      {modal &&
        (modal.mode === "view" ? (
          <Modal
            title={`Đơn hàng ${modal.data.id}`}
            onClose={() => setModal(null)}
          >
            <StatusBadge status={modal.data.status} />
            <div style={{ marginTop: 14 }}>
              {[
                ["Khách hàng", modal.data.cname],
                ["Ngày đặt", modal.data.date],
                ["Nhân viên", modal.data.staff],
                ["Phương thức", modal.data.method],
                ["Tổng tiền", fmt(modal.data.total)],
                ["Giảm giá", fmt(modal.data.discount)],
                ["Ghi chú", modal.data.note || "—"],
              ].map(([k, v]) => (
                <div
                  key={k}
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    padding: "8px 0",
                    borderBottom: `1px solid ${T.border}`,
                  }}
                >
                  <span style={{ fontSize: 13, color: T.muted }}>{k}</span>
                  <span style={{ fontSize: 13, fontWeight: 500 }}>{v}</span>
                </div>
              ))}
            </div>
            <div
              style={{
                marginTop: 16,
                display: "flex",
                gap: 8,
                justifyContent: "flex-end",
              }}
            >
              <Btn
                onClick={() => {
                  setModal(null);
                  openEdit(modal.data);
                }}
              >
                Chỉnh sửa
              </Btn>
              <Btn variant="primary" onClick={() => setModal(null)}>
                Đóng
              </Btn>
            </div>
          </Modal>
        ) : (
          <Modal
            title={modal.mode === "add" ? "Tạo đơn hàng" : "Sửa đơn hàng"}
            onClose={() => setModal(null)}
          >
            <Input
              label="Tên khách hàng"
              value={form.cname}
              onChange={(v) => setForm((f) => ({ ...f, cname: v }))}
              required
            />
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "1fr 1fr",
                gap: 12,
              }}
            >
              <Input
                label="Tổng tiền (₫)"
                type="number"
                value={String(form.total)}
                onChange={(v) =>
                  setForm((f) => ({ ...f, total: parseInt(v) || 0 }))
                }
              />
              <Input
                label="Giảm giá (₫)"
                type="number"
                value={String(form.discount)}
                onChange={(v) =>
                  setForm((f) => ({ ...f, discount: parseInt(v) || 0 }))
                }
              />
            </div>
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "1fr 1fr",
                gap: 12,
              }}
            >
              <Input
                label="Trạng thái"
                value={form.status}
                onChange={(v) => setForm((f) => ({ ...f, status: v }))}
                options={ORDER_STATUSES}
              />
              <Input
                label="Phương thức TT"
                value={form.method}
                onChange={(v) => setForm((f) => ({ ...f, method: v }))}
                options={PAY_METHODS}
              />
            </div>
            <Input
              label="Ghi chú"
              value={form.note || ""}
              onChange={(v) => setForm((f) => ({ ...f, note: v }))}
              placeholder="Ghi chú đặc biệt..."
            />
            <div
              style={{ display: "flex", gap: 10, justifyContent: "flex-end" }}
            >
              <Btn onClick={() => setModal(null)}>Hủy</Btn>
              <Btn variant="primary" onClick={save}>
                {modal.mode === "add" ? "Tạo" : "Lưu"}
              </Btn>
            </div>
          </Modal>
        ))}
      {confirm && (
        <ConfirmModal
          msg="Xóa đơn hàng này?"
          onConfirm={() => del(confirm)}
          onClose={() => setConfirm(null)}
        />
      )}
    </PageShell>
  );
}

// Products
function ProductsPage({ products, setProducts, toast }) {
  const [search, setSearch] = useState("");
  const [catF, setCatF] = useState("Tất cả");
  const [modal, setModal] = useState(null);
  const [confirm, setConfirm] = useState(null);
  const empty = {
    name: "",
    cat: "Áo thun",
    brand: "",
    price: 0,
    stock: 0,
    active: true,
  };
  const [form, setForm] = useState(empty);
  const [err, setErr] = useState({});

  const cats = ["Tất cả", ...CATEGORIES];
  const shown = products.filter((p) => {
    const q = search.toLowerCase();
    const ok =
      !q ||
      p.name.toLowerCase().includes(q) ||
      p.brand.toLowerCase().includes(q);
    const okC = catF === "Tất cả" || p.cat === catF;
    return ok && okC;
  });

  const validate = () => {
    const e = {};
    if (!form.name.trim()) e.name = "Bắt buộc";
    if (!form.brand.trim()) e.brand = "Bắt buộc";
    if (form.price <= 0) e.price = "Phải > 0";
    setErr(e);
    return !Object.keys(e).length;
  };

  const openAdd = () => {
    setForm(empty);
    setErr({});
    setModal({ mode: "add" });
  };
  const openEdit = (p) => {
    setForm({ ...p });
    setErr({});
    setModal({ mode: "edit", data: p });
  };

  const save = () => {
    if (!validate()) return;
    if (modal.mode === "add") {
      setProducts((prev) => [...prev, { ...form, id: Date.now() }]);
      toast("Thêm sản phẩm thành công");
    } else {
      setProducts((prev) =>
        prev.map((p) => (p.id === modal.data.id ? { ...p, ...form } : p))
      );
      toast("Cập nhật thành công");
    }
    setModal(null);
  };

  const del = (id) => {
    setProducts((prev) => prev.filter((p) => p.id !== id));
    setConfirm(null);
    toast("Đã xóa sản phẩm", "danger");
  };
  const toggle = (id) => {
    setProducts((prev) =>
      prev.map((p) => (p.id === id ? { ...p, active: !p.active } : p))
    );
    toast("Cập nhật trạng thái");
  };
  const ErrMsg = ({ f }) =>
    err[f] ? (
      <div
        style={{
          fontSize: 11,
          color: T.danger,
          marginTop: -10,
          marginBottom: 8,
        }}
      >
        {err[f]}
      </div>
    ) : null;

  return (
    <PageShell
      title="Sản phẩm"
      subtitle={`${products.length} sản phẩm · ${
        products.filter((p) => p.active).length
      } đang bán · ${products.filter((p) => p.stock < 50).length} sắp hết`}
      action={
        <Btn variant="primary" onClick={openAdd} icon="＋">
          Thêm sản phẩm
        </Btn>
      }
    >
      <div
        style={{ display: "flex", gap: 10, marginBottom: 14, flexWrap: "wrap" }}
      >
        <SearchBar value={search} onChange={setSearch} />
        <FilterBtns options={cats} value={catF} onChange={setCatF} />
      </div>

      <Table
        cols={[
          "Sản phẩm",
          "Danh mục",
          "Thương hiệu",
          "Giá bán",
          "Tồn kho",
          "Trạng thái",
          "Thao tác",
        ]}
        rows={shown.map((p) => (
          <TR key={p.id}>
            <TD>
              <span style={{ fontWeight: 500 }}>{p.name}</span>
            </TD>
            <TD>
              <Badge label={p.cat} bg={`${T.gold}20`} c={T.goldD} />
            </TD>
            <TD muted>{p.brand}</TD>
            <TD bold>{fmtM(p.price)}</TD>
            <TD>
              <span
                style={{
                  fontWeight: 700,
                  color:
                    p.stock < 30
                      ? T.danger
                      : p.stock < 80
                      ? T.warning
                      : T.success,
                }}
              >
                {p.stock}
              </span>
              {p.stock < 50 && (
                <span style={{ fontSize: 11, color: T.danger, marginLeft: 4 }}>
                  ⚠
                </span>
              )}
            </TD>
            <TD>
              <button
                onClick={() => toggle(p.id)}
                style={{
                  padding: "3px 10px",
                  borderRadius: 20,
                  fontSize: 12,
                  cursor: "pointer",
                  border: "none",
                  fontWeight: 500,
                  background: p.active ? T.successL : T.dangerL,
                  color: p.active ? T.successD : T.dangerD,
                }}
              >
                {p.active ? "● Đang bán" : "○ Ngừng bán"}
              </button>
            </TD>
            <TD>
              <div style={{ display: "flex", gap: 6 }}>
                <Btn size="sm" onClick={() => openEdit(p)}>
                  Sửa
                </Btn>
                <Btn size="sm" danger onClick={() => setConfirm(p.id)}>
                  Xóa
                </Btn>
              </div>
            </TD>
          </TR>
        ))}
      />

      {modal && (
        <Modal
          title={modal.mode === "add" ? "Thêm sản phẩm" : "Chỉnh sửa sản phẩm"}
          onClose={() => setModal(null)}
        >
          <Input
            label="Tên sản phẩm"
            value={form.name}
            onChange={(v) => setForm((f) => ({ ...f, name: v }))}
            required
          />
          <ErrMsg f="name" />
          <div
            style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}
          >
            <Input
              label="Danh mục"
              value={form.cat}
              onChange={(v) => setForm((f) => ({ ...f, cat: v }))}
              options={CATEGORIES}
            />
            <Input
              label="Thương hiệu"
              value={form.brand}
              onChange={(v) => setForm((f) => ({ ...f, brand: v }))}
              required
            />
          </div>
          <ErrMsg f="brand" />
          <div
            style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}
          >
            <div>
              <Input
                label="Giá bán (₫)"
                type="number"
                value={String(form.price)}
                onChange={(v) =>
                  setForm((f) => ({ ...f, price: parseInt(v) || 0 }))
                }
                required
              />
              <ErrMsg f="price" />
            </div>
            <Input
              label="Tồn kho"
              type="number"
              value={String(form.stock)}
              onChange={(v) =>
                setForm((f) => ({ ...f, stock: parseInt(v) || 0 }))
              }
            />
          </div>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 10,
              marginBottom: 16,
            }}
          >
            <input
              type="checkbox"
              checked={form.active}
              onChange={(e) =>
                setForm((f) => ({ ...f, active: e.target.checked }))
              }
              id="activeP"
            />
            <label htmlFor="activeP" style={{ fontSize: 13 }}>
              Đang bán
            </label>
          </div>
          <div style={{ display: "flex", gap: 10, justifyContent: "flex-end" }}>
            <Btn onClick={() => setModal(null)}>Hủy</Btn>
            <Btn variant="primary" onClick={save}>
              {modal.mode === "add" ? "Thêm" : "Lưu"}
            </Btn>
          </div>
        </Modal>
      )}
      {confirm && (
        <ConfirmModal
          msg="Xóa sản phẩm này?"
          onConfirm={() => del(confirm)}
          onClose={() => setConfirm(null)}
        />
      )}
    </PageShell>
  );
}

// ─── NAV ──────────────────────────────────────────────────────
const PAGES = [
  { id: "dashboard", label: "Tổng quan", emoji: "◉" },
  { id: "staff", label: "Nhân viên", emoji: "👤" },
  { id: "customers", label: "Khách hàng", emoji: "🧑‍🤝‍🧑" },
  { id: "orders", label: "Đơn hàng", emoji: "🛍" },
  { id: "products", label: "Sản phẩm", emoji: "👗" },
];

function Sidebar({ page, setPage, staff }) {
  const admin = staff.find((s) => s.role === "Admin");
  return (
    <div
      style={{
        width: 210,
        background: T.sb,
        display: "flex",
        flexDirection: "column",
        flexShrink: 0,
        height: "100vh",
        position: "sticky",
        top: 0,
      }}
    >
      <div style={{ padding: "26px 22px 18px" }}>
        <div
          style={{
            fontSize: 17,
            fontWeight: 900,
            color: "#fff",
            letterSpacing: 4,
            textTransform: "uppercase",
          }}
        >
          FASHION
        </div>
        <div
          style={{
            fontSize: 9,
            color: T.gold,
            marginTop: 3,
            letterSpacing: 5,
            textTransform: "uppercase",
            opacity: 0.9,
          }}
        >
          Management
        </div>
      </div>
      <div
        style={{ height: 1, background: T.sbBorder, margin: "0 14px 10px" }}
      />
      <nav style={{ flex: 1, padding: "0 10px", overflowY: "auto" }}>
        {PAGES.map((p) => {
          const act = page === p.id;
          return (
            <button
              key={p.id}
              onClick={() => setPage(p.id)}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 10,
                width: "100%",
                padding: "9px 12px",
                borderRadius: 8,
                border: "none",
                cursor: "pointer",
                textAlign: "left",
                marginBottom: 2,
                background: act ? "rgba(200,168,75,0.12)" : "transparent",
                color: act ? "#fff" : "rgba(255,255,255,0.42)",
                borderLeft: act
                  ? `2px solid ${T.gold}`
                  : "2px solid transparent",
                transition: "all .12s",
              }}
            >
              <span style={{ fontSize: 14 }}>{p.emoji}</span>
              <span style={{ fontSize: 13, fontWeight: act ? 600 : 400 }}>
                {p.label}
              </span>
            </button>
          );
        })}
      </nav>
      <div style={{ padding: "14px", borderTop: T.sbBorder }}>
        {admin && (
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <Avatar name={admin.name} size={30} gold />
            <div style={{ minWidth: 0 }}>
              <div
                style={{
                  fontSize: 12,
                  fontWeight: 600,
                  color: "#fff",
                  overflow: "hidden",
                  textOverflow: "ellipsis",
                  whiteSpace: "nowrap",
                }}
              >
                {admin.name.split(" ").slice(-2).join(" ")}
              </div>
              <div style={{ fontSize: 10, color: "rgba(255,255,255,0.3)" }}>
                Admin
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// ─── ROOT ─────────────────────────────────────────────────────
export default function App() {
  const [page, setPage] = useState("dashboard");
  const [staff, setStaff] = useState(initStaff);
  const [customers, setCustomers] = useState(initCustomers);
  const [orders, setOrders] = useState(initOrders);
  const [products, setProducts] = useState(initProducts);
  const [toastQ, setToastQ] = useState([]);

  const toast = (msg, type = "success") => {
    const id = Date.now();
    setToastQ((q) => [...q, { id, msg, type }]);
  };
  const removeToast = (id) => setToastQ((q) => q.filter((t) => t.id !== id));

  return (
    <div
      style={{
        display: "flex",
        height: "100vh",
        fontFamily:
          '-apple-system,BlinkMacSystemFont,"Segoe UI",system-ui,sans-serif',
        background: T.bg,
        overflow: "hidden",
      }}
    >
      <style>{`@keyframes slideUp{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}`}</style>
      <Sidebar page={page} setPage={setPage} staff={staff} />
      <div style={{ flex: 1, overflowY: "auto" }}>
        {page === "dashboard" && (
          <Dashboard
            staff={staff}
            customers={customers}
            orders={orders}
            products={products}
          />
        )}
        {page === "staff" && (
          <StaffPage staff={staff} setStaff={setStaff} toast={toast} />
        )}
        {page === "customers" && (
          <CustomersPage
            customers={customers}
            setCustomers={setCustomers}
            toast={toast}
          />
        )}
        {page === "orders" && (
          <OrdersPage
            orders={orders}
            setOrders={setOrders}
            customers={customers}
            toast={toast}
          />
        )}
        {page === "products" && (
          <ProductsPage
            products={products}
            setProducts={setProducts}
            toast={toast}
          />
        )}
      </div>
      {toastQ.map((t) => (
        <Toast
          key={t.id}
          msg={t.msg}
          type={t.type}
          onDone={() => removeToast(t.id)}
        />
      ))}
    </div>
  );
}


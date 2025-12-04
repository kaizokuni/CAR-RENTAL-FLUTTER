# Car Rental Platform - Architecture & Roadmap

## 1. System Architecture: Super Admin vs. Tenant Admin

The platform operates on a hierarchical model separating the **Platform Owner (Super Admin)** from the **Shop Owners (Tenants)**.

### A. Super Admin (Platform Owner)

- **Role:** You and your colleagues.
- **Access:** Dedicated "Admin Portal" (e.g., `admin.platform.com`).
- **Capabilities:**
  - **Tenant Provisioning:** Create new car rental shops (Tenants).
  - **Subscription Management:** Assign subscription tiers (Normal, Pro, Premium) to tenants.
  - **Master Access:** Ability to access tenant dashboards for support/maintenance.
  - **Platform Analytics:** View global revenue, total shops, etc.

### B. Tenant Admin (Shop Owner)

- **Role:** The owner of a specific car rental business (e.g., "Avis").
- **Access:** Dedicated Subdomain (e.g., `avis.platform.com`).
- **Capabilities:**
  - **Fleet Management:** Add/Remove cars.
  - **Booking Management:** Handle rentals.
  - **Staff Management:** Create accounts for their employees.
  - **RBAC:** Assign roles to employees (e.g., "Manager", "Assistant").

### C. Tenant Staff (Assistant/Manager)

- **Role:** Employees of the shop owner.
- **Access:** Same subdomain as the owner.
- **Capabilities:** Restricted by roles assigned by the Shop Owner.
  - _Example:_ An "Assistant" can view bookings but cannot delete cars or view financial reports.

---

## 2. Subscription System (Feature Gating)

Features are gated based on the Tenant's subscription tier.

| Feature            | Normal (Basic) | Pro |  Premium  |
| :----------------- | :------------: | :-: | :-------: |
| Car Limit          |       10       | 50  | Unlimited |
| Staff Accounts     |       1        |  5  | Unlimited |
| Financial Reports  |       ❌       | ✅  |    ✅     |
| Advanced Analytics |       ❌       | ❌  |    ✅     |
| Custom Branding    |       ❌       | ✅  |    ✅     |

**Implementation:**

- **Database:** `tenants` table will have `subscription_tier` and `subscription_status` columns.
- **Middleware:** `SubscriptionMiddleware` will check if a tenant has access to a requested feature/endpoint.
- **Frontend:** UI elements (buttons, menu items) will be hidden/disabled based on the tier.

---

## 3. Role-Based Access Control (RBAC) within Tenants

Shop Owners can assign roles to their staff to control access.

**Roles:**

1.  **Owner (Admin):** Full access to everything in the tenant.
2.  **Manager:** Can manage fleet and bookings, view basic reports. Cannot delete data or manage subscription.
3.  **Assistant:** Can view/create bookings. Cannot view financials or modify fleet.

**Implementation:**

- **Database:** `roles` table in each Tenant DB.
- **Permissions:** `permissions` table or JSON field defining what each role can do (e.g., `can_delete_cars`, `can_view_financials`).
- **Middleware:** `RBACMiddleware` checks user permissions for specific actions.

---

## 4. Implementation Plan

### Phase 1: Super Admin Core (Current Focus)

- [x] Disable public signup.
- [x] Create "Super Admin" Tenant Creation Interface.
- [ ] **Action Item:** Create "Admin Portal" Tenant (Seed Script).
- [ ] **Action Item:** Create initial Super Admin User (Seed Script).

### Phase 2: Subscription & Schema Updates

- [ ] **Database:** Add `subscription_tier` to `tenants` table.
- [ ] **Backend:** Update `CreateTenant` handler to accept subscription tier.
- [ ] **Backend:** Implement `SubscriptionMiddleware`.

### Phase 3: Tenant RBAC

- [ ] **Database:** Enhance `roles` table with permissions.
- [ ] **Backend:** Implement `RBACMiddleware`.
- [ ] **Frontend:** Update Tenant Dashboard to hide elements based on Role.

---

## 5. Admin Credentials & Access

**How to Access the Super Admin Panel:**

1.  **URL:** You will access via a dedicated subdomain, e.g., `http://admin.localhost:5173`.
2.  **Credentials:**
    - **Email:** `superadmin@platform.com` (Created via seed script)
    - **Password:** (Set via seed script)

**How to Access a Tenant Shop:**

1.  **URL:** `http://<subdomain>.localhost:5173`
2.  **Credentials:** Provided by you (Super Admin) when creating the tenant.

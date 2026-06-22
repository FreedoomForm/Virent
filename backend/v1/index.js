const express = require('express');
const path = require("path");
const router = express.Router();
const authModel = require("./models/auth.js");
const routeAuth = require("./route/auth.js");
const routeAdmins = require("./route/admins.js");
const routeScooters = require("./route/scooters.js");
const routeCities = require("./route/cities.js");
const routeUsers = require("./route/users.js");
const routePrepaids = require("./route/prepaid.js");

// --- New routes (Phase 1+) ---
const routeTrips = require("./route/trips.js");
const routeSms = require("./route/sms.js");
const routeAuthExt = require("./route/auth_ext.js");
const routeTransactions = require("./route/transactions.js");
const routePromocodes = require("./route/promocodes.js");
const routeSupport = require("./route/support.js");
const routeAuditlog = require("./route/auditlog.js");
const routeNotifications = require("./route/notifications.js");
const routeJuicers = require("./route/juicers.js");
const routeMechanics = require("./route/mechanics.js");
const routeGeofencing = require("./route/geofencing.js");
const routeUploads = require("./route/uploads.js");
// --- Iteration 2 additions ---
const routeIot = require("./route/iot.js");
const routeDiscovery = require("./route/discovery.js");
const routeUserSettings = require("./route/user_settings.js");
const routeStats = require("./route/stats.js");
const routeSystem = require("./route/system.js");
const routeAdminExt = require("./route/admin_ext.js");
// --- Iteration: exports + search ---
const routeExports = require("./src/modules/exports/export.routes.js");
const routeSearch = require("./src/modules/search/search.routes.js");
const routeTwofa = require("./src/modules/twofa/twofa.routes.js");
const routeUserExt = require("./src/modules/users/api/user.routes.js");
const routeCityExt = require("./src/modules/cities/api/city.routes.js");
const routeReceipts = require("./src/modules/receipts/receipt.routes.js");
const routeFavorites = require("./src/modules/favorites/api/favorite.routes.js");
const routeCityInfo = require("./src/modules/cities/api/city-info.routes.js");
const routeLegal = require("./src/modules/legal/legal.routes.js");
const routePublic = require("./src/modules/public/public.routes.js");

// All requests require valid API key (except webhooks)
router.all('*', authModel.checkAPIKey);

router.get('/',
    (req, res) => res.sendFile(path.join(__dirname + '/documentation/documentation.html')));

router.use("/auth", routeAuth);
router.use("/auth", routeAuthExt);   // extended auth (refresh, SMS, reset)
router.use("/admins", routeAdmins);
router.use("/scooters", routeScooters);
router.use("/cities", routeCities);
router.use("/users", routeUsers);
router.use("/prepaids", routePrepaids);

// New
router.use("/trips", routeTrips);
router.use("/sms", routeSms);
router.use("/transactions", routeTransactions);
router.use("/promocodes", routePromocodes);
router.use("/support", routeSupport);
router.use("/audit-log", routeAuditlog);
router.use("/notifications", routeNotifications);
router.use("/juicers", routeJuicers);
router.use("/mechanics", routeMechanics);
router.use("/geofencing", routeGeofencing);
router.use("/uploads", routeUploads);
// Iteration 2
router.use("/iot", routeIot);
router.use("/discovery", routeDiscovery);
router.use("/user-settings", routeUserSettings);
router.use("/stats", routeStats);
router.use("/system", routeSystem);
router.use("/admin", routeAdminExt);  // extended admin features (block, refund, bulk prepaid, push composer, etc.)
router.use("/exports", routeExports);
router.use("/search", routeSearch);
router.use("/2fa", routeTwofa);
router.use("/users-v2", routeUserExt);
router.use("/cities-v2", routeCityExt);
router.use("/receipts", routeReceipts);
router.use("/favorites", routeFavorites);
router.use("/cities-info", routeCityInfo);
router.use("/legal", routeLegal);
router.use("/public", routePublic);

// Webhooks — no API key check needed (they have their own signature verification)
// But we need to bypass the global checkAPIKey middleware. We do this by registering
// them with their own path prefix BEFORE the checkAPIKey runs.
// Actually, the cleanest way: webhooks accept API key in body, or we can have a
// separate top-level router in app.js. For now, we keep them here and clients
// must pass api_key in body.

router.use(function (req, res) {
    return res.status(404).json({
        errors: {
            status: 404,
            source: req.path,
            title: "Not found",
            detail: "Could not find path: " + req.path,
        }
    });
});

module.exports = router;

from flask import session

ROLE_DASHBOARD_CONFIG = {
    "admin": {
        "role_label": "Admin",
        "profile_name": "Admin User",
        "profile_role": "Administrator",
        "profile_url": "/admin/profile",
        "profile_image": "https://ui-avatars.com/api/?name=Admin+User&background=1d4ed8&color=fff&bold=true",
        "nav_sections": [
            {
                "title": "Management",
                "items": [
                    {"label": "Dashboard", "key": "dashboard", "href": "/admin/dashboard", "icon": "solar:home-linear"},
                    {"label": "Company", "key": "company", "href": "/admin/company", "icon": "mdi:office-building-outline"},
                    {"label": "Subscription", "key": "subscription", "href": "/admin/subscription", "icon": "solar:bookmark-linear"},
                    {"label": "Users", "key": "users", "href": "/admin/users", "icon": "solar:user-linear"},
                    {"label": "Support", "key": "support", "href": "/admin/support", "icon": "mdi:headset"},
                    {"label": "Notification", "key": "notification", "href": "/admin/notification", "icon": "solar:bell-linear"},
                    {"label": "Interview Management", "key": "interview-management", "href": "/admin/interview-management", "icon": "mdi:message-text-outline"},
                    {"label": "Profile", "key": "profile", "href": "/admin/profile", "icon": "solar:user-circle-linear"},
                    {"label": "Settings", "key": "settings", "href": "/admin/settings", "icon": "solar:settings-linear"},
                    {"label": "Activities", "key": "activities", "href": "/admin/activities", "icon": "mdi:history"},
                ],
            },
        ],
        "notifications": [
            {"icon": "solar:user-plus-linear", "title": "18 new users registered", "subtitle": "This month", "tone": "text-emerald-500"},
            {"icon": "solar:file-text-linear", "title": "7 company requests pending review", "subtitle": "Today", "tone": "text-blue-500"},
        ],
    },
    "companies": {
        "role_label": "Companies",
        "profile_name": "Company Admin",
        "profile_role": "Company Portal",
        "profile_url": "/companies/profile",
        "profile_image": "https://ui-avatars.com/api/?name=Company+Admin&background=0f766e&color=fff&bold=true",
        "nav_sections": [
            {
                "title": "Workspace",
                "items": [
                    {"label": "Dashboard", "key": "dashboard", "href": "/companies/dashboard", "icon": "solar:home-linear"},
                    {"label": "Users", "key": "users", "href": "/companies/users", "icon": "solar:user-linear"},
                    {"label": "Subscription", "key": "subscription", "href": "/companies/subscription", "icon": "solar:bookmark-linear"},
                    {"label": "Interview Management", "key": "interview-management", "href": "/companies/interview-management", "icon": "mdi:message-text-outline"},
                    {"label": "Support", "key": "support", "href": "/companies/support", "icon": "mdi:headset"},
                    {"label": "Notification", "key": "notification", "href": "/companies/notification", "icon": "solar:bell-linear"},
                    {"label": "Profile", "key": "profile", "href": "/companies/profile", "icon": "solar:user-circle-linear"},
                    {"label": "Settings", "key": "settings", "href": "/companies/settings", "icon": "solar:settings-linear"},
                ],
            },
        ],
        "notifications": [
            {"icon": "mdi:account-group-outline", "title": "4 new team members joined", "subtitle": "This week", "tone": "text-emerald-500"},
            {"icon": "solar:ticket-linear", "title": "2 support tickets need attention", "subtitle": "Open today", "tone": "text-amber-500"},
        ],
    },
    "client": {
        "role_label": "Client",
        "profile_name": "Client User",
        "profile_role": "Learner Account",
        "profile_url": "/client/profile",
        "profile_image": "https://ui-avatars.com/api/?name=Client+User&background=7c3aed&color=fff&bold=true",
        "nav_sections": [
            {
                "title": "Workspace",
                "items": [
                    {"label": "Dashboard", "key": "dashboard", "href": "/client/dashboard", "icon": "solar:home-linear"},
                    {"label": "Subscription", "key": "subscription", "href": "/client/subscription", "icon": "solar:bookmark-linear"},
                    {"label": "Interview", "key": "interview", "href": "/client/interview", "icon": "solar:microphone-linear"},
                    {"label": "Notification", "key": "notification", "href": "/client/notification", "icon": "solar:bell-linear"},
                    {"label": "Support", "key": "support", "href": "/client/support", "icon": "mdi:headset"},
                    {"label": "Profile", "key": "profile", "href": "/client/profile", "icon": "solar:user-circle-linear"},
                    {"label": "Settings", "key": "settings", "href": "/client/settings", "icon": "solar:settings-linear"},
                ],
            },
        ],
        "notifications": [
            {"icon": "solar:microphone-linear", "title": "Practice session ready", "subtitle": "Today", "tone": "text-violet-500"},
            {"icon": "solar:bookmark-linear", "title": "Plan renewal due soon", "subtitle": "Next 3 days", "tone": "text-sky-500"},
        ],
    },
    "company_user": {
        "role_label": "Company User",
        "profile_name": "Team Member",
        "profile_role": "Company Employee",
        "profile_url": "/client/profile",
        "profile_image": "https://ui-avatars.com/api/?name=Team+Member&background=059669&color=fff&bold=true",
        "nav_sections": [
            {
                "title": "Workspace",
                "items": [
                    {"label": "Interview", "key": "interview", "href": "/client/interview", "icon": "solar:microphone-linear"},
                    {"label": "Notification", "key": "notification", "href": "/client/notification", "icon": "solar:bell-linear"},
                    {"label": "Support", "key": "support", "href": "/client/support", "icon": "mdi:headset"},
                    {"label": "Profile", "key": "profile", "href": "/client/profile", "icon": "solar:user-circle-linear"},
                ],
            },
        ],
        "notifications": [
            {"icon": "solar:microphone-linear", "title": "Practice session ready", "subtitle": "Today", "tone": "text-violet-500"},
            {"icon": "solar:bookmark-linear", "title": "Company plan active", "subtitle": "Managed by admin", "tone": "text-sky-500"},
        ],
    },
}

PAGE_LABELS = {
    "dashboard": "Dashboard",
    "company": "Company",
    "subscription": "Subscription",
    "users": "Users",
    "support": "Support",
    "notification": "Notification",
    "interview-management": "Interview Management",
    "interview": "Interview",
    "profile": "Profile",
    "settings": "Settings",
    "activities": "Activities",
}

def build_dashboard_context(role_key, page_key):
    role_config = ROLE_DASHBOARD_CONFIG.get(role_key, ROLE_DASHBOARD_CONFIG.get("client"))
    page_label = PAGE_LABELS.get(page_key, page_key.replace("-", " ").title())
    
    context = {
        "role_key": role_key,
        "role_label": role_config.get("role_label", "User"),
        "current_page": page_key,
        "page_label": page_label,
        "page_summary": "",
        "page_url": f"/{role_key}/{page_key}",
        "brand_name": "AI Interviewer",
        "brand_initial": "A",
        "nav_sections": [
            {
                "title": section.get("title", ""),
                "items": [{**item, "active": item.get("key") == page_key} for item in section.get("items", [])],
            }
            for section in role_config.get("nav_sections", [])
        ],
        "notification_count": session.get("notification_count", 0),
        "notification_url": f"/{role_key}/notification",
        "profile_name": session.get("full_name", role_config.get("profile_name")),
        "profile_role": role_config.get("profile_role", "Account"),
        "profile_url": role_config.get("profile_url", "#"),
        "profile_image": session.get("profile_image") or role_config.get("profile_image", ""),
        "stats": [],
        "ui_notifications": session.get("ui_notifications", role_config.get("notifications", [])),
        "overview_cards": [],
        "recent_users": [],
        "recent_companies": [],
        "recent_activity": [],
        "recent_sessions": [],
        "latest_subscription": {
            "status": "active",
            "plan_name": "Premium Plan",
            "billing_cycle": "monthly",
            "price": 29.00,
            "currency": "USD",
            "end_date": "December 31, 2024"
        },
        "renew_text": "Active",
        "actions": [],
    }

    # Static Mock Stats
    if role_key == "admin":
        context["stats"] = [
            {"label": "Total Users", "value": "1,250", "icon": "solar:users-group-rounded-bold-duotone", "note": "Registered"},
            {"label": "Companies", "value": "45", "icon": "solar:buildings-bold-duotone", "note": "Active"},
            {"label": "Interviews", "value": "3,420", "icon": "solar:microphone-bold-duotone", "note": "Completed"},
            {"label": "Support", "value": "12", "icon": "mdi:headset", "note": "Open tickets"}
        ]
    elif role_key == "companies":
        context["stats"] = [
            {"label": "Team Members", "value": "24", "icon": "solar:users-group-rounded-bold-duotone", "note": "Active"},
            {"label": "Interviews", "value": "156", "icon": "solar:microphone-bold-duotone", "note": "Conducted"},
            {"label": "Revenue", "value": "$12,450", "icon": "solar:bookmark-linear", "note": "This month"},
            {"label": "Support", "value": "2", "icon": "mdi:headset", "note": "Open tickets"}
        ]
    else:
        context["stats"] = [
            {"label": "Total Interviews", "value": "12", "icon": "solar:microphone-bold-duotone", "note": "Started"},
            {"label": "Completed", "value": "10", "icon": "solar:check-circle-bold-duotone", "note": "Finished"},
            {"label": "Avg Score", "value": "85%", "icon": "solar:chart-square-bold-duotone", "note": "Performance"},
            {"label": "Practice Streak", "value": "7", "icon": "solar:fire-bold-duotone", "note": "Days"}
        ]

    return context

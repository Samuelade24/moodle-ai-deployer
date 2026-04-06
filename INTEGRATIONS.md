# Moodle SMS & Student Management Integration

## 📱 SMS Integration

### Installed SMS Gateways
- **Custom API SMS Gateway** - Works with any SMS provider (Twilio, MessageBird, etc.)

### Configuration
1. Go to Site administration → Plugins → Message outputs → SMS
2. Add your SMS gateway
3. Configure API settings

### Supported SMS Providers
- Twilio
- MessageBird
- TextMagic
- Any provider with HTTP API

## 👥 Student Management System

### Supporter Plugin Features
- ✅ Find and manage students in one interface
- ✅ Enroll/unenroll users from courses
- ✅ Create new courses
- ✅ View student details
- ✅ Login as any user for support
- ✅ View enrolled courses per user
- ✅ Check authentication types
- ✅ View suspension status

### Access
- **URL**: `/admin/tool/supporter`
- **Permissions**: Requires `tool/supporter:use` capability

### Quick Commands
```bash
# View student statistics
sudo mysql -e "SELECT COUNT(*) FROM mdl_user WHERE deleted=0"

# Enable supporter for a role
sudo -u www-data php admin/cli/assign_capability.php --role=manager --cap=tool/supporter:use --permit=1
```

## 🔧 Troubleshooting

### Database connection issues
```bash
sudo service mysql start
sudo service apache2 restart
```

### Clear cache
```bash
sudo rm -rf /var/moodledata/cache/*
```

## 📊 System Status
- Moodle Version: 4.5.10+
- SMS Gateway: Ready for configuration
- Student Management: Active

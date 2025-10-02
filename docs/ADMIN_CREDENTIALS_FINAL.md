# Admin Credentials - Final Configuration

## Admin Account Details

**Username**: `admin`  
**Password**: `IZTs:%$jS^@b2`  
**Status**: Active ✅  
**Privileges**: Superuser + Staff ✅

## Database Information
- **Database**: `user_db`
- **User ID**: 2
- **Email**: admin@example.com
- **Password Hash**: bcrypt with 12 rounds

## Verification Status

✅ **Direct API Login** (port 8001): Working  
✅ **API Gateway Login** (port 8000): Working  
✅ **Frontend Login** (port 3000): Ready to test  
✅ **Superuser Privileges**: Confirmed  

## Login Endpoints

### Production (Frontend uses this):
```bash
POST http://154.114.10.123:8000/api/auth/login/
Content-Type: application/json

{
  "username": "admin",
  "password": "IZTs:%$jS^@b2"
}
```

### Development:
```bash
POST http://localhost:8000/api/auth/login/
```

## Security Notes

- Password uses bcrypt hashing with salt factor 12
- Demo credentials removed from login UI
- All special characters properly escaped in password hash
- Password contains: uppercase, lowercase, numbers, special chars

## Troubleshooting

If login fails:
1. Verify API Gateway is healthy: `curl http://localhost:8000/health`
2. Test direct user-service: `curl -X POST http://localhost:8001/auth/login -d '{"username":"admin","password":"IZTs:%$jS^@b2"}'`
3. Check user status: `docker exec postgres psql -U postgres -d user_db -c "SELECT username, is_active, is_superuser FROM users WHERE username='admin';"`

**Last Updated**: 2025-10-01  
**Status**: Fully Operational ✅

import { AppBar, Toolbar, Typography, Button, Box, Chip, Stack } from '@mui/material'
import { Link as RouterLink, useNavigate, useLocation } from 'react-router-dom'
import PeopleIcon from '@mui/icons-material/People'
import AssessmentIcon from '@mui/icons-material/Assessment'
import HealthAndSafetyIcon from '@mui/icons-material/HealthAndSafety'
import LogoutIcon from '@mui/icons-material/Logout'
import AccountCircleIcon from '@mui/icons-material/AccountCircle'
import { useAuth } from '../context/AuthContext'

export default function Navbar() {
  const { user, logout, isAuthenticated } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()

  const handleLogout = async () => {
    await logout()
    navigate('/login')
  }

  if (!isAuthenticated) return null

  const getRoleColor = (role) => {
    switch (role) {
      case 'admin':
        return 'primary'
      case 'hr_manager':
        return 'success'
      case 'auditor':
        return 'warning'
      default:
        return 'default'
    }
  }

  const formatRole = (role) => {
    switch (role) {
      case 'hr_manager':
        return 'HR Manager'
      case 'admin':
        return 'Admin'
      case 'auditor':
        return 'Auditor'
      default:
        return role || 'User'
    }
  }

  return (
    <AppBar position="sticky" sx={{ bgcolor: '#111827', borderBottom: '1px solid #1f2937', boxShadow: 'none' }}>
      <Toolbar sx={{ justifyContent: 'space-between', px: { xs: 2, md: 4 } }}>
        <Stack direction="row" spacing={3} alignItems="center">
          <Typography
            variant="h6"
            component={RouterLink}
            to="/employees"
            sx={{
              fontWeight: 800,
              letterSpacing: 1,
              color: '#38bdf8',
              textDecoration: 'none',
              display: 'flex',
              alignItems: 'center',
              gap: 1,
            }}
          >
            ACME SALARY
          </Typography>

          <Stack direction="row" spacing={1}>
            <Button
              component={RouterLink}
              to="/employees"
              startIcon={<PeopleIcon />}
              variant={location.pathname.startsWith('/employees') ? 'contained' : 'text'}
              size="small"
              sx={{ textTransform: 'none', fontWeight: 600 }}
            >
              Employees
            </Button>
            <Button
              component={RouterLink}
              to="/analytics"
              startIcon={<AssessmentIcon />}
              variant={location.pathname === '/analytics' ? 'contained' : 'text'}
              size="small"
              sx={{ textTransform: 'none', fontWeight: 600 }}
            >
              Analytics
            </Button>
            <Button
              component={RouterLink}
              to="/health"
              startIcon={<HealthAndSafetyIcon />}
              variant={location.pathname === '/health' ? 'contained' : 'text'}
              size="small"
              sx={{ textTransform: 'none', fontWeight: 600 }}
            >
              Health
            </Button>
          </Stack>
        </Stack>

        <Stack direction="row" spacing={2} alignItems="center">
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <AccountCircleIcon fontSize="small" sx={{ color: 'text.secondary' }} />
            <Typography variant="body2" sx={{ display: { xs: 'none', sm: 'block' }, color: 'text.secondary' }}>
              {user?.full_name || user?.email}
            </Typography>
            <Chip
              label={formatRole(user?.role)}
              color={getRoleColor(user?.role)}
              size="small"
              sx={{ fontWeight: 600, textTransform: 'uppercase', fontSize: '0.65rem' }}
            />
          </Box>

          <Button
            variant="outlined"
            color="error"
            size="small"
            startIcon={<LogoutIcon />}
            onClick={handleLogout}
            sx={{ textTransform: 'none', fontSize: '0.8rem' }}
          >
            Logout
          </Button>
        </Stack>
      </Toolbar>
    </AppBar>
  )
}

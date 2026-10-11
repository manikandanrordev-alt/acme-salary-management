import { AppBar, Toolbar, Typography, Button, Box, Chip, Stack } from '@mui/material'
import { Link as RouterLink, useNavigate, useLocation } from 'react-router-dom'
import PeopleIcon from '@mui/icons-material/People'
import AssessmentIcon from '@mui/icons-material/Assessment'
import ReceiptLongIcon from '@mui/icons-material/ReceiptLong'
import AutoAwesomeIcon from '@mui/icons-material/AutoAwesome'
import HealthAndSafetyIcon from '@mui/icons-material/HealthAndSafety'
import LogoutIcon from '@mui/icons-material/Logout'
import AccountCircleIcon from '@mui/icons-material/AccountCircle'
import CurrencyRupeeIcon from '@mui/icons-material/CurrencyRupee'
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
        return 'HR Director'
      case 'admin':
        return 'System Admin'
      case 'auditor':
        return 'Auditor'
      default:
        return role || 'User'
    }
  }

  return (
    <AppBar position="sticky" sx={{ bgcolor: 'rgba(8, 12, 20, 0.95)', backdropFilter: 'blur(16px)', borderBottom: '1px solid #1e293b', boxShadow: 'none', zIndex: 1100 }}>
      <Toolbar sx={{ justifyContent: 'space-between', px: { xs: 2, md: 4 }, py: 0.5 }}>
        <Stack direction="row" spacing={3} alignItems="center">
          <Typography
            variant="h6"
            component={RouterLink}
            to="/employees"
            sx={{
              fontWeight: 900,
              letterSpacing: 1.2,
              background: 'linear-gradient(135deg, #38bdf8 0%, #818cf8 100%)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              textDecoration: 'none',
              display: 'flex',
              alignItems: 'center',
              gap: 1,
            }}
          >
            <CurrencyRupeeIcon sx={{ color: '#38bdf8' }} />
            ACME PAYROLL
          </Typography>

          <Stack direction="row" spacing={1} sx={{ display: { xs: 'none', md: 'flex' } }}>
            <Button
              component={RouterLink}
              to="/employees"
              startIcon={<PeopleIcon />}
              variant={location.pathname.startsWith('/employees') ? 'contained' : 'text'}
              size="small"
              sx={{ textTransform: 'none', fontWeight: 600, borderRadius: 2 }}
            >
              Employees
            </Button>
            <Button
              component={RouterLink}
              to="/payslips"
              startIcon={<ReceiptLongIcon />}
              variant={location.pathname.startsWith('/payslips') ? 'contained' : 'text'}
              size="small"
              sx={{ textTransform: 'none', fontWeight: 600, borderRadius: 2 }}
            >
              Payslips & Payroll
            </Button>
            <Button
              component={RouterLink}
              to="/analytics"
              startIcon={<AssessmentIcon />}
              variant={location.pathname === '/analytics' ? 'contained' : 'text'}
              size="small"
              sx={{ textTransform: 'none', fontWeight: 600, borderRadius: 2 }}
            >
              Analytics (₹)
            </Button>
            <Button
              component={RouterLink}
              to="/ai-advisor"
              startIcon={<AutoAwesomeIcon sx={{ color: '#f59e0b' }} />}
              variant={location.pathname === '/ai-advisor' ? 'contained' : 'text'}
              size="small"
              sx={{ textTransform: 'none', fontWeight: 600, borderRadius: 2 }}
            >
              AI Advisor
            </Button>
            <Button
              component={RouterLink}
              to="/health"
              startIcon={<HealthAndSafetyIcon />}
              variant={location.pathname === '/health' ? 'contained' : 'text'}
              size="small"
              sx={{ textTransform: 'none', fontWeight: 600, borderRadius: 2 }}
            >
              Health
            </Button>
          </Stack>
        </Stack>

        <Stack direction="row" spacing={2} alignItems="center">
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <span className="live-pulse" title="System Operational" />
            <AccountCircleIcon fontSize="small" sx={{ color: 'text.secondary' }} />
            <Typography variant="body2" sx={{ display: { xs: 'none', sm: 'block' }, color: 'text.secondary', fontWeight: 500 }}>
              {user?.full_name || user?.email}
            </Typography>
            <Chip
              label={formatRole(user?.role)}
              color={getRoleColor(user?.role)}
              size="small"
              sx={{ fontWeight: 700, textTransform: 'uppercase', fontSize: '0.65rem', letterSpacing: 0.5 }}
            />
          </Box>

          <Button
            variant="outlined"
            color="error"
            size="small"
            startIcon={<LogoutIcon />}
            onClick={handleLogout}
            sx={{ textTransform: 'none', fontSize: '0.8rem', borderRadius: 2, borderColor: '#ef4444' }}
          >
            Logout
          </Button>
        </Stack>
      </Toolbar>
    </AppBar>
  )
}

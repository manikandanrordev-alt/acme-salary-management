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
import AccountBalanceIcon from '@mui/icons-material/AccountBalance'
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

  const displayName = user?.full_name ? user.full_name.replace(/\s*\([^)]*\)/g, '').trim() : (user?.email || 'User')

  const getNavBtnStyle = (pathPrefix) => {
    const isActive = location.pathname.startsWith(pathPrefix)
    return {
      textTransform: 'none',
      fontWeight: isActive ? 700 : 500,
      fontSize: '0.84rem',
      borderRadius: '8px',
      px: 1.6,
      py: 0.6,
      color: isActive ? '#38bdf8' : '#94a3b8',
      bgcolor: isActive ? 'rgba(56, 189, 248, 0.12)' : 'transparent',
      border: isActive ? '1px solid rgba(56, 189, 248, 0.35)' : '1px solid transparent',
      boxShadow: isActive ? '0 0 12px rgba(56, 189, 248, 0.15)' : 'none',
      transition: 'all 0.2s ease',
      '&:hover': {
        bgcolor: isActive ? 'rgba(56, 189, 248, 0.18)' : 'rgba(255, 255, 255, 0.05)',
        color: '#f8fafc',
      },
    }
  }

  return (
    <AppBar position="sticky" sx={{ bgcolor: 'rgba(6, 10, 18, 0.96)', backdropFilter: 'blur(20px)', borderBottom: '1px solid #1a253c', boxShadow: '0 4px 20px rgba(0,0,0,0.4)', zIndex: 1100 }}>
      <Toolbar sx={{ justifyContent: 'space-between', px: { xs: 2, md: 3 }, minHeight: 64 }}>
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
              fontSize: '1.1rem',
            }}
          >
            <CurrencyRupeeIcon sx={{ color: '#38bdf8' }} />
            ACME PAYROLL
          </Typography>

          <Stack direction="row" spacing={0.8} sx={{ display: { xs: 'none', md: 'flex' } }}>
            <Button
              component={RouterLink}
              to="/employees"
              startIcon={<PeopleIcon fontSize="small" />}
              size="small"
              sx={getNavBtnStyle('/employees')}
            >
              Employees
            </Button>
            <Button
              component={RouterLink}
              to="/payslips"
              startIcon={<ReceiptLongIcon fontSize="small" />}
              size="small"
              sx={getNavBtnStyle('/payslips')}
            >
              Payslips & Payroll
            </Button>
            <Button
              component={RouterLink}
              to="/hr-suite"
              startIcon={<AccountBalanceIcon fontSize="small" sx={{ color: '#38bdf8' }} />}
              size="small"
              sx={getNavBtnStyle('/hr-suite')}
            >
              HR Executive Suite
            </Button>
            <Button
              component={RouterLink}
              to="/analytics"
              startIcon={<AssessmentIcon fontSize="small" />}
              size="small"
              sx={getNavBtnStyle('/analytics')}
            >
              Analytics (₹)
            </Button>
            <Button
              component={RouterLink}
              to="/ai-advisor"
              startIcon={<AutoAwesomeIcon fontSize="small" sx={{ color: '#f59e0b' }} />}
              size="small"
              sx={getNavBtnStyle('/ai-advisor')}
            >
              AI Advisor
            </Button>
            <Button
              component={RouterLink}
              to="/health"
              startIcon={<HealthAndSafetyIcon fontSize="small" />}
              size="small"
              sx={getNavBtnStyle('/health')}
            >
              Health
            </Button>
          </Stack>
        </Stack>

        <Stack direction="row" spacing={2} alignItems="center">
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <span className="live-pulse" title="System Operational" />
            <AccountCircleIcon fontSize="small" sx={{ color: '#94a3b8' }} />
            <Typography variant="body2" sx={{ display: { xs: 'none', sm: 'block' }, color: '#f8fafc', fontWeight: 600, fontSize: '0.85rem' }}>
              {displayName}
            </Typography>
            <Chip
              label={formatRole(user?.role)}
              color={getRoleColor(user?.role)}
              size="small"
              sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.65rem', letterSpacing: 0.5, height: 22 }}
            />
          </Box>

          <Button
            variant="outlined"
            color="error"
            size="small"
            startIcon={<LogoutIcon fontSize="small" />}
            onClick={handleLogout}
            sx={{ textTransform: 'none', fontSize: '0.8rem', borderRadius: '8px', borderColor: 'rgba(239, 68, 68, 0.5)', px: 1.5, py: 0.4 }}
          >
            Logout
          </Button>
        </Stack>
      </Toolbar>
    </AppBar>
  )
}

import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Container,
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  Box,
  Alert,
  Divider,
  Stack,
  Chip,
  CircularProgress,
  InputAdornment,
  IconButton,
} from '@mui/material'
import LockOutlinedIcon from '@mui/icons-material/LockOutlined'
import ShieldIcon from '@mui/icons-material/Shield'
import Visibility from '@mui/icons-material/Visibility'
import VisibilityOff from '@mui/icons-material/VisibilityOff'
import { useAuth } from '../context/AuthContext'

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [loginError, setLoginError] = useState('')

  const { login, isAuthenticated } = useAuth()
  const navigate = useNavigate()

  useEffect(() => {
    if (isAuthenticated) {
      navigate('/employees', { replace: true })
    }
  }, [isAuthenticated, navigate])

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!email || !password) {
      setLoginError('Please enter both email and password')
      return
    }

    setSubmitting(true)
    setLoginError('')

    const res = await login(email, password)
    setSubmitting(false)

    if (res.success) {
      navigate('/employees', { replace: true })
    } else {
      setLoginError(res.error || 'Invalid credentials')
    }
  }

  const handleQuickLogin = (demoEmail, demoPassword) => {
    setEmail(demoEmail)
    setPassword(demoPassword)
    setLoginError('')
  }

  return (
    <Container maxWidth="sm" sx={{ py: 10 }}>
      <Box sx={{ textAlign: 'center', mb: 4 }}>
        <Box
          sx={{
            display: 'inline-flex',
            alignItems: 'center',
            justifyContent: 'center',
            width: 56,
            height: 56,
            borderRadius: '50%',
            bgcolor: 'primary.dark',
            color: 'primary.contrastText',
            mb: 2,
          }}
        >
          <LockOutlinedIcon fontSize="large" />
        </Box>
        <Typography variant="overline" color="primary" sx={{ letterSpacing: 2, fontWeight: 700, display: 'block' }}>
          ACME ENTERPRISE
        </Typography>
        <Typography variant="h4" component="h1" fontWeight={800}>
          Salary & Compensation Intelligence
        </Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
          Sign in to securely view compensation, record effective-dated revisions, and review audit logs.
        </Typography>
      </Box>

      <Card sx={{ bgcolor: '#111827', border: '1px solid #1f2937', borderRadius: 3, boxShadow: 3 }}>
        <CardContent sx={{ p: 4 }}>
          {loginError && (
            <Alert severity="error" sx={{ mb: 3 }}>
              {loginError}
            </Alert>
          )}

          <Box component="form" onSubmit={handleSubmit} noValidate>
            <TextField
              margin="normal"
              required
              fullWidth
              id="email"
              label="Email Address"
              name="email"
              autoComplete="email"
              autoFocus
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              sx={{ mb: 2 }}
            />
            <TextField
              margin="normal"
              required
              fullWidth
              name="password"
              label="Password"
              type={showPassword ? 'text' : 'password'}
              id="password"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              slotProps={{
                input: {
                  endAdornment: (
                    <InputAdornment position="end">
                      <IconButton
                        aria-label="toggle visibility"
                        onClick={() => setShowPassword((show) => !show)}
                        edge="end"
                        size="small"
                        sx={{ color: 'text.secondary' }}
                      >
                        {showPassword ? <VisibilityOff fontSize="small" /> : <Visibility fontSize="small" />}
                      </IconButton>
                    </InputAdornment>
                  ),
                },
              }}
              sx={{ mb: 3 }}
            />

            <Button
              type="submit"
              fullWidth
              variant="contained"
              size="large"
              disabled={submitting}
              sx={{ py: 1.5, fontWeight: 700, textTransform: 'none' }}
            >
              {submitting ? <CircularProgress size={24} color="inherit" /> : 'Sign In'}
            </Button>
          </Box>

          <Divider sx={{ my: 4, borderColor: '#1f2937' }}>
            <Typography variant="caption" color="text.secondary">
              QUICK DEMO CREDENTIALS
            </Typography>
          </Divider>

          <Stack spacing={1.5}>
            <Button
              variant="outlined"
              size="small"
              onClick={() => handleQuickLogin('hr_director@acme.com', 'Password123!')}
              sx={{ justifyContent: 'space-between', textTransform: 'none', borderColor: '#374151' }}
            >
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <ShieldIcon fontSize="small" color="success" />
                <Typography variant="body2" fontWeight={600}>
                  hr_director@acme.com
                </Typography>
              </Box>
              <Chip label="HR Manager (Full Access)" size="small" color="success" sx={{ fontSize: '0.7rem' }} />
            </Button>

            <Button
              variant="outlined"
              size="small"
              onClick={() => handleQuickLogin('compliance@acme.com', 'Password123!')}
              sx={{ justifyContent: 'space-between', textTransform: 'none', borderColor: '#374151' }}
            >
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <ShieldIcon fontSize="small" color="warning" />
                <Typography variant="body2" fontWeight={600}>
                  compliance@acme.com
                </Typography>
              </Box>
              <Chip label="Auditor (Read-Only)" size="small" color="warning" sx={{ fontSize: '0.7rem' }} />
            </Button>

            <Button
              variant="outlined"
              size="small"
              onClick={() => handleQuickLogin('admin@acme.com', 'Password123!')}
              sx={{ justifyContent: 'space-between', textTransform: 'none', borderColor: '#374151' }}
            >
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <ShieldIcon fontSize="small" color="primary" />
                <Typography variant="body2" fontWeight={600}>
                  admin@acme.com
                </Typography>
              </Box>
              <Chip label="System Admin" size="small" color="primary" sx={{ fontSize: '0.7rem' }} />
            </Button>
          </Stack>

          <Box sx={{ mt: 2.5, p: 1.5, bgcolor: '#0b0f19', borderRadius: 1.5, border: '1px solid #1f2937', textAlign: 'center' }}>
            <Typography variant="caption" color="text.secondary">
              Demo password for all accounts: <strong style={{ color: '#38bdf8' }}>Password123!</strong>
            </Typography>
          </Box>
        </CardContent>
      </Card>
    </Container>
  )
}

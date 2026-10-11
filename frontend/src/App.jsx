import { useState, useEffect } from 'react'
import {
  ThemeProvider,
  createTheme,
  CssBaseline,
  Container,
  Box,
  Typography,
  Card,
  CardContent,
  Chip,
  Button,
  CircularProgress,
  Alert,
  Stack,
  Divider,
} from '@mui/material'
import CheckCircleIcon from '@mui/icons-material/CheckCircle'
import ErrorIcon from '@mui/icons-material/Error'
import RefreshIcon from '@mui/icons-material/Refresh'
import StorageIcon from '@mui/icons-material/Storage'
import SecurityIcon from '@mui/icons-material/Security'
import PeopleIcon from '@mui/icons-material/People'
import apiClient from './api/client'

const darkTheme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#2563eb',
    },
    secondary: {
      main: '#10b981',
    },
    background: {
      default: '#0b0f19',
      paper: '#111827',
    },
  },
  typography: {
    fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
  },
})

export default function App() {
  const [health, setHealth] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const checkHealth = async (isInitial = false) => {
    if (!isInitial) setLoading(true)
    setError(null)
    try {
      const response = await apiClient.get('/api/v1/health')
      setHealth(response.data)
    } catch (err) {
      setError(err.message || 'Failed to connect to Rails backend')
      setHealth(null)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    let ignore = false
    apiClient
      .get('/api/v1/health')
      .then((res) => {
        if (!ignore) {
          setHealth(res.data)
          setLoading(false)
        }
      })
      .catch((err) => {
        if (!ignore) {
          setError(err.message || 'Failed to connect to Rails backend')
          setHealth(null)
          setLoading(false)
        }
      })
    return () => {
      ignore = true
    }
  }, [])

  return (
    <ThemeProvider theme={darkTheme}>
      <CssBaseline />
      <Box sx={{ minHeight: '100vh', py: 6 }}>
        <Container maxWidth="md">
          {/* Header */}
          <Box sx={{ mb: 4, textAlign: 'center' }}>
            <Typography variant="overline" color="primary" sx={{ letterSpacing: 2, fontWeight: 700 }}>
              ACME ENTERPRISE
            </Typography>
            <Typography variant="h3" component="h1" fontWeight={800} gutterBottom>
              Salary Management System
            </Typography>
            <Typography variant="subtitle1" color="text.secondary">
              Multinational Compensation Intelligence & Audit Platform (10,000 Employees)
            </Typography>
          </Box>

          {/* System Status Card */}
          <Card sx={{ mb: 4, borderRadius: 3, border: '1px solid #1f2937' }}>
            <CardContent sx={{ p: 4 }}>
              <Stack direction="row" sx={{ justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Typography variant="h6" fontWeight={700}>
                  System Health & Connectivity
                </Typography>
                <Button
                  variant="outlined"
                  size="small"
                  startIcon={<RefreshIcon />}
                  onClick={checkHealth}
                  disabled={loading}
                >
                  Refresh
                </Button>
              </Stack>

              {loading ? (
                <Box sx={{ display: 'flex', alignItems: 'center', py: 4, justifyContent: 'center' }}>
                  <CircularProgress size={32} sx={{ mr: 2 }} />
                  <Typography color="text.secondary">Connecting to Rails API...</Typography>
                </Box>
              ) : error ? (
                <Alert severity="error" icon={<ErrorIcon />} sx={{ mb: 2 }}>
                  Backend Communication Error: {error}
                </Alert>
              ) : (
                <Stack spacing={2}>
                  <Alert severity="success" icon={<CheckCircleIcon />}>
                    Backend connected successfully: <strong>{health?.service}</strong>
                  </Alert>

                  <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} sx={{ pt: 1 }}>
                    <Box sx={{ flex: 1, p: 2, bgcolor: '#1f2937', borderRadius: 2 }}>
                      <Typography variant="caption" color="text.secondary">
                        API STATUS
                      </Typography>
                      <Box sx={{ mt: 1, display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Chip
                          label={health?.status?.toUpperCase() || 'OK'}
                          color="success"
                          size="small"
                        />
                      </Box>
                    </Box>

                    <Box sx={{ flex: 1, p: 2, bgcolor: '#1f2937', borderRadius: 2 }}>
                      <Typography variant="caption" color="text.secondary">
                        DATABASE (MySQL 8)
                      </Typography>
                      <Box sx={{ mt: 1, display: 'flex', alignItems: 'center', gap: 1 }}>
                        <StorageIcon fontSize="small" color="primary" />
                        <Typography variant="body2" fontWeight={600}>
                          {health?.db === 'connected' ? 'Connected' : 'Disconnected'}
                        </Typography>
                      </Box>
                    </Box>

                    <Box sx={{ flex: 1, p: 2, bgcolor: '#1f2937', borderRadius: 2 }}>
                      <Typography variant="caption" color="text.secondary">
                        SERVER TIMESTAMP
                      </Typography>
                      <Typography variant="body2" sx={{ mt: 1, fontFamily: 'monospace' }}>
                        {health?.timestamp ? new Date(health.timestamp).toLocaleTimeString() : 'N/A'}
                      </Typography>
                    </Box>
                  </Stack>
                </Stack>
              )}
            </CardContent>
          </Card>

          {/* Architecture Summary Cards */}
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={3} sx={{ mb: 4 }}>
            <Card sx={{ flex: 1, borderRadius: 3, border: '1px solid #1f2937' }}>
              <CardContent>
                <PeopleIcon color="primary" sx={{ mb: 1 }} />
                <Typography variant="h6" fontWeight={700} gutterBottom>
                  10,000 Employees
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  High-performance server-side indexing, pagination, and multi-field filtering.
                </Typography>
              </CardContent>
            </Card>

            <Card sx={{ flex: 1, borderRadius: 3, border: '1px solid #1f2937' }}>
              <CardContent>
                <SecurityIcon color="primary" sx={{ mb: 1 }} />
                <Typography variant="h6" fontWeight={700} gutterBottom>
                  Devise Cookie Auth
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  HttpOnly session protection, CSRF validation, and strict RBAC authorization.
                </Typography>
              </CardContent>
            </Card>

            <Card sx={{ flex: 1, borderRadius: 3, border: '1px solid #1f2937' }}>
              <CardContent>
                <StorageIcon color="primary" sx={{ mb: 1 }} />
                <Typography variant="h6" fontWeight={700} gutterBottom>
                  Audit Integrity
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Effective-dated salary revisions and immutable transactional audit logs.
                </Typography>
              </CardContent>
            </Card>
          </Stack>

          <Divider sx={{ my: 3, borderColor: '#1f2937' }} />

          <Typography variant="caption" color="text.secondary" sx={{ display: 'block', textAlign: 'center' }}>
            ACME Salary Management &bull; Milestone 1 Initialized &bull; Incubyte Assessment
          </Typography>
        </Container>
      </Box>
    </ThemeProvider>
  )
}

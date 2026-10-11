import { useState, useEffect } from 'react'
import {
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
} from '@mui/material'
import CheckCircleIcon from '@mui/icons-material/CheckCircle'
import ErrorIcon from '@mui/icons-material/Error'
import RefreshIcon from '@mui/icons-material/Refresh'
import StorageIcon from '@mui/icons-material/Storage'
import apiClient from '../api/client'

export default function HealthPage() {
  const [health, setHealth] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const checkHealth = async () => {
    setLoading(true)
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
    checkHealth()
  }, [])

  return (
    <Container maxWidth="md" sx={{ py: 6 }}>
      <Box sx={{ mb: 4, textAlign: 'center' }}>
        <Typography variant="overline" color="primary" sx={{ letterSpacing: 2, fontWeight: 700 }}>
          INFRASTRUCTURE MONITOR
        </Typography>
        <Typography variant="h4" component="h1" fontWeight={800} gutterBottom>
          System Health & Service Status
        </Typography>
      </Box>

      <Card sx={{ mb: 4, borderRadius: 3, border: '1px solid #1f2937', bgcolor: '#111827' }}>
        <CardContent sx={{ p: 4 }}>
          <Stack direction="row" sx={{ justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
            <Typography variant="h6" fontWeight={700}>
              Rails API & MySQL Connection Pool
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
    </Container>
  )
}

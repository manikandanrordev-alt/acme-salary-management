import { useState, useEffect, useCallback } from 'react'
import {
  Container,
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  Button,
  Tabs,
  Tab,
  CircularProgress,
  Alert,
  Stack,
  Paper,
  Divider,
} from '@mui/material'
import AssessmentIcon from '@mui/icons-material/Assessment'
import RefreshIcon from '@mui/icons-material/Refresh'
import PeopleIcon from '@mui/icons-material/People'
import BusinessIcon from '@mui/icons-material/Business'
import PublicIcon from '@mui/icons-material/Public'
import apiClient from '../api/client'

export default function AnalyticsPage() {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [selectedCurrency, setSelectedCurrency] = useState('ALL')

  const fetchAnalytics = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const res = await apiClient.get('/api/v1/analytics/summary')
      setData(res.data.data)
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Failed to load compensation analytics')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchAnalytics()
  }, [fetchAnalytics])

  const formatCurrency = (amount, currency) => {
    if (amount === undefined || amount === null) return 'N/A'
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: currency || 'USD',
      maximumFractionDigits: 0,
    }).format(amount)
  }

  if (loading) {
    return (
      <Container maxWidth="xl" sx={{ py: 10, textAlign: 'center' }}>
        <CircularProgress size={44} />
        <Typography variant="body1" color="text.secondary" sx={{ mt: 2 }}>
          Aggregating compensation metrics across 10,000 employees...
        </Typography>
      </Container>
    )
  }

  if (error) {
    return (
      <Container maxWidth="xl" sx={{ py: 6 }}>
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
        <Button variant="outlined" startIcon={<RefreshIcon />} onClick={fetchAnalytics}>
          Retry Aggregation
        </Button>
      </Container>
    )
  }

  const currencies = data?.currencies || []
  const departments = data?.departments || []
  const countries = data?.countries || []

  // Filtered views based on selected currency tab
  const filteredDepartments =
    selectedCurrency === 'ALL'
      ? departments
      : departments.filter((d) => d.currency === selectedCurrency)

  const filteredCountries =
    selectedCurrency === 'ALL'
      ? countries
      : countries.filter((c) => c.currency === selectedCurrency)

  return (
    <Container maxWidth="xl" sx={{ py: 4 }}>
      {/* Header */}
      <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 2 }}>
        <Box>
          <Stack direction="row" spacing={1.5} alignItems="center">
            <AssessmentIcon color="primary" fontSize="large" />
            <Typography variant="h4" component="h1" fontWeight={800}>
              Compensation Intelligence
            </Typography>
          </Stack>
          <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
            Enterprise multi-currency payroll distribution and department analytics strictly grouped by currency to prevent cross-currency pollution.
          </Typography>
        </Box>

        <Button
          variant="outlined"
          size="small"
          startIcon={<RefreshIcon />}
          onClick={fetchAnalytics}
          sx={{ textTransform: 'none' }}
        >
          Refresh Data
        </Button>
      </Box>

      {/* Currency KPI Summary Cards */}
      <Typography variant="h6" fontWeight={700} sx={{ mb: 2 }}>
        Active Payroll by Currency
      </Typography>

      <Grid container spacing={3} sx={{ mb: 4 }}>
        {currencies.map((curr) => (
          <Grid xs={12} sm={6} md={2.4} key={curr.currency}>
            <Card
              sx={{
                bgcolor: '#111827',
                border: selectedCurrency === curr.currency ? '2px solid #38bdf8' : '1px solid #1f2937',
                borderRadius: 3,
                cursor: 'pointer',
                transition: 'all 0.2s',
                '&:hover': { borderColor: '#38bdf8' },
              }}
              onClick={() => setSelectedCurrency(curr.currency)}
            >
              <CardContent sx={{ p: 2.5 }}>
                <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 1.5 }}>
                  <Chip
                    label={curr.currency}
                    color="primary"
                    size="small"
                    sx={{ fontWeight: 800, fontFamily: 'monospace' }}
                  />
                  <Stack direction="row" spacing={0.5} alignItems="center">
                    <PeopleIcon fontSize="inherit" color="action" />
                    <Typography variant="caption" fontWeight={600} color="text.secondary">
                      {curr.headcount.toLocaleString()} emps
                    </Typography>
                  </Stack>
                </Stack>

                <Typography variant="caption" color="text.secondary">
                  TOTAL ANNUAL PAYROLL
                </Typography>
                <Typography variant="h6" fontWeight={800} color="#34d399">
                  {formatCurrency(curr.total_payroll, curr.currency)}
                </Typography>

                <Divider sx={{ my: 1.5, borderColor: '#1f2937' }} />

                <Stack spacing={0.5}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography variant="caption" color="text.secondary">
                      Average:
                    </Typography>
                    <Typography variant="caption" fontWeight={700}>
                      {formatCurrency(curr.average_salary, curr.currency)}
                    </Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography variant="caption" color="text.secondary">
                      Range:
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {formatCurrency(curr.min_salary, curr.currency)} - {formatCurrency(curr.max_salary, curr.currency)}
                    </Typography>
                  </Box>
                </Stack>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Currency Filter Tabs */}
      <Paper sx={{ bgcolor: '#111827', border: '1px solid #1f2937', mb: 3 }}>
        <Tabs
          value={selectedCurrency}
          onChange={(_, val) => setSelectedCurrency(val)}
          indicatorColor="primary"
          textColor="primary"
          variant="scrollable"
          scrollButtons="auto"
        >
          <Tab label="ALL CURRENCIES" value="ALL" sx={{ fontWeight: 700 }} />
          {currencies.map((c) => (
            <Tab key={c.currency} label={`${c.currency} ONLY`} value={c.currency} sx={{ fontWeight: 700 }} />
          ))}
        </Tabs>
      </Paper>

      {/* Department & Country Tables */}
      <Grid container spacing={3}>
        {/* Department Breakdown */}
        <Grid xs={12} lg={7}>
          <Card sx={{ bgcolor: '#111827', border: '1px solid #1f2937', borderRadius: 3 }}>
            <CardContent sx={{ p: 3 }}>
              <Stack direction="row" spacing={1.5} alignItems="center" sx={{ mb: 2 }}>
                <BusinessIcon color="primary" />
                <Typography variant="h6" fontWeight={700}>
                  Department Breakdown ({filteredDepartments.length} segments)
                </Typography>
              </Stack>

              <TableContainer>
                <Table size="small">
                  <TableHead sx={{ bgcolor: '#1f2937' }}>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Department</TableCell>
                      <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Currency</TableCell>
                      <TableCell align="right" sx={{ fontWeight: 700, color: '#e5e7eb' }}>
                        Headcount
                      </TableCell>
                      <TableCell align="right" sx={{ fontWeight: 700, color: '#e5e7eb' }}>
                        Average Salary
                      </TableCell>
                      <TableCell align="right" sx={{ fontWeight: 700, color: '#e5e7eb' }}>
                        Total Payroll
                      </TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {filteredDepartments.map((dept, idx) => (
                      <TableRow key={`${dept.department_id}-${dept.currency}-${idx}`} hover>
                        <TableCell fontWeight={600}>{dept.department_name}</TableCell>
                        <TableCell>
                          <Chip label={dept.currency} size="small" variant="outlined" />
                        </TableCell>
                        <TableCell align="right">{dept.headcount.toLocaleString()}</TableCell>
                        <TableCell align="right" sx={{ fontWeight: 600 }}>
                          {formatCurrency(dept.average_salary, dept.currency)}
                        </TableCell>
                        <TableCell align="right" sx={{ fontWeight: 700, color: '#34d399' }}>
                          {formatCurrency(dept.total_payroll, dept.currency)}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>

        {/* Country Breakdown */}
        <Grid xs={12} lg={5}>
          <Card sx={{ bgcolor: '#111827', border: '1px solid #1f2937', borderRadius: 3 }}>
            <CardContent sx={{ p: 3 }}>
              <Stack direction="row" spacing={1.5} alignItems="center" sx={{ mb: 2 }}>
                <PublicIcon color="primary" />
                <Typography variant="h6" fontWeight={700}>
                  Country Breakdown ({filteredCountries.length} regions)
                </Typography>
              </Stack>

              <TableContainer>
                <Table size="small">
                  <TableHead sx={{ bgcolor: '#1f2937' }}>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Country</TableCell>
                      <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Currency</TableCell>
                      <TableCell align="right" sx={{ fontWeight: 700, color: '#e5e7eb' }}>
                        Headcount
                      </TableCell>
                      <TableCell align="right" sx={{ fontWeight: 700, color: '#e5e7eb' }}>
                        Average Salary
                      </TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {filteredCountries.map((c, idx) => (
                      <TableRow key={`${c.country_code}-${c.currency}-${idx}`} hover>
                        <TableCell sx={{ fontWeight: 700 }}>{c.country_code}</TableCell>
                        <TableCell>
                          <Chip label={c.currency} size="small" variant="outlined" />
                        </TableCell>
                        <TableCell align="right">{c.headcount.toLocaleString()}</TableCell>
                        <TableCell align="right" sx={{ fontWeight: 600 }}>
                          {formatCurrency(c.average_salary, c.currency)}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Container>
  )
}

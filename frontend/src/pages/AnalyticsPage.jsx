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
  CircularProgress,
  Alert,
  Stack,
  Divider,
  LinearProgress,
} from '@mui/material'
import AssessmentIcon from '@mui/icons-material/Assessment'
import RefreshIcon from '@mui/icons-material/Refresh'
import CelebrationIcon from '@mui/icons-material/Celebration'
import AccountBalanceIcon from '@mui/icons-material/AccountBalance'
import EventBusyIcon from '@mui/icons-material/EventBusy'
import BusinessIcon from '@mui/icons-material/Business'
import apiClient from '../api/client'
import { formatINR, formatLakhsCrores } from '../utils/currency'

export default function AnalyticsPage() {
  const [data, setData] = useState(null)
  const [payslipSummary, setPayslipSummary] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const fetchAnalytics = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const [analyticsRes, payslipRes] = await Promise.all([
        apiClient.get('/api/v1/analytics/summary'),
        apiClient.get('/api/v1/payslips?payroll_month=2026-10&per_page=1'),
      ])
      setData(analyticsRes.data.data)
      setPayslipSummary(payslipRes.data.summary || null)
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Failed to load compensation analytics')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchAnalytics()
  }, [fetchAnalytics])

  if (loading) {
    return (
      <Container maxWidth="xl" sx={{ py: 10, textAlign: 'center' }}>
        <CircularProgress size={44} sx={{ color: '#38bdf8' }} />
        <Typography variant="body1" color="text.secondary" sx={{ mt: 2 }}>
          Aggregating Indian compensation metrics, tax liabilities, and Diwali bonus distributions...
        </Typography>
      </Container>
    )
  }

  if (error) {
    return (
      <Container maxWidth="xl" sx={{ py: 6 }}>
        <Alert severity="error" sx={{ mb: 3 }}>{error}</Alert>
        <Button variant="outlined" startIcon={<RefreshIcon />} onClick={fetchAnalytics}>
          Retry Aggregation
        </Button>
      </Container>
    )
  }

  const departments = data?.departments || []
  const totalEmployees = data?.total_employees || 10000

  // Standardize amounts to INR
  const totalGrossINR = payslipSummary?.total_gross_inr || 125000000.0
  const totalNetINR = payslipSummary?.total_net_disbursed_inr || 105000000.0
  const totalTdsINR = payslipSummary?.total_tds_tax_inr || 12000000.0
  const totalEpfINR = payslipSummary?.total_epf_inr || 7500000.0
  const totalDiwaliINR = payslipSummary?.total_diwali_bonus_inr || 42500000.0

  return (
    <Container maxWidth="xl" sx={{ py: 4 }}>
      {/* Header */}
      <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 2 }}>
        <Box>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <AssessmentIcon sx={{ color: '#38bdf8', fontSize: 36 }} />
            <Typography variant="h4" component="h1" fontWeight={900}>
              Compensation & Tax Intelligence (₹ INR)
            </Typography>
          </Box>
          <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
            Enterprise multi-dimensional payroll analytics denominated strictly in Indian Rupees (₹), Indian New Tax Regime deductions, and Diwali bonus provisions.
          </Typography>
        </Box>
        <Button variant="outlined" size="small" startIcon={<RefreshIcon />} onClick={fetchAnalytics} sx={{ textTransform: 'none' }}>
          Refresh Data
        </Button>
      </Box>

      {/* Top Level Metric Cards (in INR) */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={2.4}>
          <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
            <CardContent sx={{ p: 2.5 }}>
              <Typography variant="caption" color="text.secondary" fontWeight={700}>
                TOTAL ANNUAL PAYROLL (₹)
              </Typography>
              <Typography variant="h5" fontWeight={900} color="#38bdf8" sx={{ mt: 0.5 }}>
                {formatLakhsCrores(totalGrossINR * 12)}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                Across {totalEmployees.toLocaleString()} employees
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={2.4}>
          <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
            <CardContent sx={{ p: 2.5 }}>
              <Typography variant="caption" color="text.secondary" fontWeight={700}>
                MONTHLY NET DISBURSED (₹)
              </Typography>
              <Typography variant="h5" fontWeight={900} color="#34d399" sx={{ mt: 0.5 }}>
                {formatLakhsCrores(totalNetINR)}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                Net direct bank remittances
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={2.4}>
          <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
            <CardContent sx={{ p: 2.5 }}>
              <Typography variant="caption" color="text.secondary" fontWeight={700}>
                GOVT TDS TAX WITHHELD (₹)
              </Typography>
              <Typography variant="h5" fontWeight={900} color="#f59e0b" sx={{ mt: 0.5 }}>
                {formatLakhsCrores(totalTdsINR)}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                New Tax Regime FY 24-25
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={2.4}>
          <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
            <CardContent sx={{ p: 2.5 }}>
              <Typography variant="caption" color="text.secondary" fontWeight={700}>
                🪔 DIWALI FESTIVE BONUS (₹)
              </Typography>
              <Typography variant="h5" fontWeight={900} color="#c084fc" sx={{ mt: 0.5 }}>
                {formatLakhsCrores(totalDiwaliINR)}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                8.33% statutory annual festive pool
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={2.4}>
          <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
            <CardContent sx={{ p: 2.5 }}>
              <Typography variant="caption" color="text.secondary" fontWeight={700}>
                STATUTORY EPF REMITTED (₹)
              </Typography>
              <Typography variant="h5" fontWeight={900} color="#60a5fa" sx={{ mt: 0.5 }}>
                {formatLakhsCrores(totalEpfINR)}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                12% Employee Provident Fund
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Visual Payroll Composition & Deductions Bar */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} md={7}>
          <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2, height: '100%' }}>
            <CardContent sx={{ p: 3 }}>
              <Typography variant="h6" fontWeight={800} gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <AccountBalanceIcon sx={{ color: '#38bdf8' }} /> Indian Payroll Deductions & Disbursement Structure
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                Proportional breakdown of monthly payroll gross into Take-Home Salary, Income Tax TDS, EPF, and Festive Bonus.
              </Typography>

              {/* Stacked Visual Bar */}
              <Box sx={{ mb: 3 }}>
                <Box sx={{ display: 'flex', height: 28, borderRadius: 1.5, overflow: 'hidden', mb: 1 }}>
                  <Box sx={{ width: '68%', bgcolor: '#10b981', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Typography variant="caption" fontWeight={700} color="#fff">Net Pay 68%</Typography>
                  </Box>
                  <Box sx={{ width: '15%', bgcolor: '#f59e0b', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Typography variant="caption" fontWeight={700} color="#fff">TDS 15%</Typography>
                  </Box>
                  <Box sx={{ width: '10%', bgcolor: '#38bdf8', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Typography variant="caption" fontWeight={700} color="#fff">EPF 10%</Typography>
                  </Box>
                  <Box sx={{ width: '7%', bgcolor: '#c084fc', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Typography variant="caption" fontWeight={700} color="#fff">Bonus 7%</Typography>
                  </Box>
                </Box>

                <Stack direction="row" spacing={3} sx={{ mt: 2 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Box sx={{ width: 12, height: 12, borderRadius: '50%', bgcolor: '#10b981' }} />
                    <Typography variant="caption" color="text.secondary">Net Pay (Take-home)</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Box sx={{ width: 12, height: 12, borderRadius: '50%', bgcolor: '#f59e0b' }} />
                    <Typography variant="caption" color="text.secondary">Govt TDS (Tax)</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Box sx={{ width: 12, height: 12, borderRadius: '50%', bgcolor: '#38bdf8' }} />
                    <Typography variant="caption" color="text.secondary">EPF (12%)</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Box sx={{ width: 12, height: 12, borderRadius: '50%', bgcolor: '#c084fc' }} />
                    <Typography variant="caption" color="text.secondary">Diwali Bonus</Typography>
                  </Box>
                </Stack>
              </Box>

              <Divider sx={{ my: 2, borderColor: '#1e293b' }} />

              {/* Tax Slab Metrics */}
              <Typography variant="subtitle2" fontWeight={800} color="#38bdf8" sx={{ mb: 1.5 }}>
                Indian Income Tax New Regime Slabs Applied:
              </Typography>
              <Grid container spacing={1.5}>
                <Grid item xs={6} sm={4}>
                  <Box sx={{ p: 1.5, bgcolor: '#1e293b', borderRadius: 1.5 }}>
                    <Typography variant="caption" color="text.secondary">Up to ₹3,00,000</Typography>
                    <Typography variant="body2" fontWeight={700} color="#34d399">0% (Nil)</Typography>
                  </Box>
                </Grid>
                <Grid item xs={6} sm={4}>
                  <Box sx={{ p: 1.5, bgcolor: '#1e293b', borderRadius: 1.5 }}>
                    <Typography variant="caption" color="text.secondary">₹3,00,001 - ₹7,00,000</Typography>
                    <Typography variant="body2" fontWeight={700} color="#38bdf8">5%</Typography>
                  </Box>
                </Grid>
                <Grid item xs={6} sm={4}>
                  <Box sx={{ p: 1.5, bgcolor: '#1e293b', borderRadius: 1.5 }}>
                    <Typography variant="caption" color="text.secondary">₹7,00,001 - ₹10,00,000</Typography>
                    <Typography variant="body2" fontWeight={700} color="#f59e0b">10%</Typography>
                  </Box>
                </Grid>
                <Grid item xs={6} sm={4}>
                  <Box sx={{ p: 1.5, bgcolor: '#1e293b', borderRadius: 1.5 }}>
                    <Typography variant="caption" color="text.secondary">₹10,00,001 - ₹12,00,000</Typography>
                    <Typography variant="body2" fontWeight={700} color="#f59e0b">15%</Typography>
                  </Box>
                </Grid>
                <Grid item xs={6} sm={4}>
                  <Box sx={{ p: 1.5, bgcolor: '#1e293b', borderRadius: 1.5 }}>
                    <Typography variant="caption" color="text.secondary">₹12,00,001 - ₹15,00,000</Typography>
                    <Typography variant="body2" fontWeight={700} color="#f87171">20%</Typography>
                  </Box>
                </Grid>
                <Grid item xs={6} sm={4}>
                  <Box sx={{ p: 1.5, bgcolor: '#1e293b', borderRadius: 1.5 }}>
                    <Typography variant="caption" color="text.secondary">Above ₹15,00,000</Typography>
                    <Typography variant="body2" fontWeight={700} color="#ef4444">30%</Typography>
                  </Box>
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* Diwali Bonus & Leave Utilization */}
        <Grid item xs={12} md={5}>
          <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2, height: '100%' }}>
            <CardContent sx={{ p: 3 }}>
              <Typography variant="h6" fontWeight={800} gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <CelebrationIcon sx={{ color: '#f59e0b' }} /> Diwali Festive Bonus & Leave Analytics
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Statutory bonus disbursement compliance and Loss of Pay (LOP) impact metrics.
              </Typography>

              <Box sx={{ p: 2, bgcolor: '#1e293b', borderRadius: 2, mb: 2.5 }}>
                <Typography variant="caption" color="text.secondary">ANNUAL FESTIVE BONUS WINDOW</Typography>
                <Typography variant="h6" fontWeight={800} color="#f59e0b">
                  October &mdash; November 2026
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Statutory rate: <strong>8.33% of Basic Salary</strong> under Payment of Bonus Act
                </Typography>
              </Box>

              <Box sx={{ mb: 2.5 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                  <Typography variant="body2" color="text.secondary">Paid Leave Utilization Rate</Typography>
                  <Typography variant="body2" fontWeight={700} color="#34d399">94.2%</Typography>
                </Box>
                <LinearProgress variant="determinate" value={94.2} color="success" sx={{ height: 6, borderRadius: 3 }} />
              </Box>

              <Box sx={{ mb: 2.5 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                  <Typography variant="body2" color="text.secondary">Loss of Pay (LOP) Ratio</Typography>
                  <Typography variant="body2" fontWeight={700} color="#f87171">1.8%</Typography>
                </Box>
                <LinearProgress variant="determinate" value={1.8} color="error" sx={{ height: 6, borderRadius: 3 }} />
              </Box>

              <Box sx={{ p: 2, bgcolor: '#0b0f19', borderRadius: 2, border: '1px solid #334155' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <EventBusyIcon sx={{ color: '#38bdf8', fontSize: 20 }} />
                  <Typography variant="subtitle2" fontWeight={700} color="#38bdf8">
                    Paid Leave Policy Rule
                  </Typography>
                </Box>
                <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 0.5 }}>
                  Each employee receives 24 annual paid leaves. Unpaid days result in pro-rata salary deduction: (Monthly Gross / 30) &times; LOP Days.
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Department Breakdown Table in INR */}
      <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
        <CardContent sx={{ p: 3 }}>
          <Typography variant="h6" fontWeight={800} sx={{ mb: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
            <BusinessIcon sx={{ color: '#38bdf8' }} /> Department-wise Payroll Breakdown (₹ INR)
          </Typography>

          <TableContainer>
            <Table size="small">
              <TableHead sx={{ bgcolor: '#1e293b' }}>
                <TableRow>
                  <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Department</TableCell>
                  <TableCell align="right" sx={{ fontWeight: 700, color: '#e5e7eb' }}>Headcount</TableCell>
                  <TableCell align="right" sx={{ fontWeight: 700, color: '#e5e7eb' }}>Average CTC (₹ LPA)</TableCell>
                  <TableCell align="right" sx={{ fontWeight: 700, color: '#e5e7eb' }}>Total Annual Payroll (₹)</TableCell>
                  <TableCell align="right" sx={{ fontWeight: 700, color: '#e5e7eb' }}>Diwali Bonus Pool (₹)</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {departments.map((dept, idx) => {
                  const avgLpa = dept.average_salary ? (Number(dept.average_salary) >= 300000 ? Number(dept.average_salary) : Number(dept.average_salary) * 85) : 1800000
                  const totalPayroll = avgLpa * (dept.headcount || 1)
                  const diwaliPool = totalPayroll * 0.50 * 0.0833

                  return (
                    <TableRow key={idx} hover sx={{ '&:hover': { bgcolor: 'rgba(255, 255, 255, 0.04)' } }}>
                      <TableCell sx={{ fontWeight: 700 }}>
                        {dept.department_name}
                        <Chip label={dept.currency || 'INR'} size="small" variant="outlined" sx={{ ml: 1, fontSize: '0.65rem' }} />
                      </TableCell>
                      <TableCell align="right">{dept.headcount?.toLocaleString()}</TableCell>
                      <TableCell align="right" sx={{ fontWeight: 600, color: '#38bdf8' }}>
                        {formatINR(avgLpa, { decimals: 0 })}
                      </TableCell>
                      <TableCell align="right" sx={{ fontWeight: 700, color: '#34d399' }}>
                        {formatLakhsCrores(totalPayroll)}
                      </TableCell>
                      <TableCell align="right" sx={{ fontWeight: 700, color: '#c084fc' }}>
                        {formatLakhsCrores(diwaliPool)}
                      </TableCell>
                    </TableRow>
                  )
                })}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>
    </Container>
  )
}

import { useState, useEffect, useCallback } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import {
  Container,
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  Chip,
  Button,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  MenuItem,
  Alert,
  CircularProgress,
  Divider,
  Paper,
} from '@mui/material'
import ArrowBackIcon from '@mui/icons-material/ArrowBack'
import EditCalendarIcon from '@mui/icons-material/EditCalendar'
import HistoryIcon from '@mui/icons-material/History'
import MonetizationOnIcon from '@mui/icons-material/MonetizationOn'
import PersonIcon from '@mui/icons-material/Person'
import BusinessIcon from '@mui/icons-material/Business'
import PublicIcon from '@mui/icons-material/Public'
import CalendarTodayIcon from '@mui/icons-material/CalendarToday'
import apiClient from '../api/client'
import { useAuth } from '../context/AuthContext'

const CURRENCIES = ['USD', 'GBP', 'EUR', 'INR', 'SGD']
const REASONS = [
  { value: 'annual_merit', label: 'Annual Merit Increase' },
  { value: 'promotion', label: 'Promotion / Job Level Upgrade' },
  { value: 'market_adjustment', label: 'Market Rate Adjustment' },
  { value: 'role_change', label: 'Role / Department Transfer' },
  { value: 'cost_of_living', label: 'Cost of Living Adjustment (COLA)' },
  { value: 'initial_offer', label: 'Initial Offer / Base Onboarding' },
]

export default function EmployeeDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { isHrManager } = useAuth()

  const [employee, setEmployee] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [successMessage, setSuccessMessage] = useState(null)

  // Revision Modal State
  const [openModal, setOpenModal] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [formError, setFormError] = useState(null)
  const [revisionForm, setRevisionForm] = useState({
    amount: '',
    currency: 'USD',
    effective_from: '',
    change_reason: 'annual_merit',
    pay_frequency: 'annual',
  })

  const fetchEmployee = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const res = await apiClient.get(`/api/v1/employees/${id}`)
      setEmployee(res.data.data)
      // Initialize modal default currency to match employee currency
      if (res.data.data?.current_salary?.currency) {
        setRevisionForm((prev) => ({
          ...prev,
          currency: res.data.data.current_salary.currency,
        }))
      }
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Failed to load employee details')
    } finally {
      setLoading(false)
    }
  }, [id])

  useEffect(() => {
    fetchEmployee()
  }, [fetchEmployee])

  const handleOpenRevisionModal = () => {
    const activeSalary = employee?.current_salary
    const defaultDate = new Date().toISOString().split('T')[0]

    setRevisionForm({
      amount: activeSalary ? String(Number(activeSalary.amount) * 1.05) : '',
      currency: activeSalary?.currency || 'USD',
      effective_from: defaultDate,
      change_reason: 'annual_merit',
      pay_frequency: activeSalary?.pay_frequency || 'annual',
    })
    setFormError(null)
    setOpenModal(true)
  }

  const handleCloseRevisionModal = () => {
    if (!submitting) {
      setOpenModal(false)
      setFormError(null)
    }
  }

  const handleSubmitRevision = async (e) => {
    e.preventDefault()
    setFormError(null)

    const amountNum = parseFloat(revisionForm.amount)
    if (isNaN(amountNum) || amountNum <= 0) {
      setFormError('Salary amount must be a positive number')
      return
    }

    if (!revisionForm.effective_from) {
      setFormError('Effective start date is required')
      return
    }

    const activeSalary = employee?.current_salary
    if (activeSalary && revisionForm.effective_from <= activeSalary.effective_from) {
      setFormError(
        `New effective date (${revisionForm.effective_from}) must be strictly after the current active record start date (${activeSalary.effective_from})`
      )
      return
    }

    setSubmitting(true)
    try {
      await apiClient.post(`/api/v1/employees/${id}/salary_revisions`, {
        amount: amountNum,
        currency: revisionForm.currency,
        effective_from: revisionForm.effective_from,
        change_reason: revisionForm.change_reason,
        pay_frequency: revisionForm.pay_frequency,
      })

      setSuccessMessage('Salary revision recorded successfully with transactional audit trail.')
      setOpenModal(false)
      fetchEmployee()
    } catch (err) {
      setFormError(err.response?.data?.error?.message || 'Failed to record salary revision')
    } finally {
      setSubmitting(false)
    }
  }

  const formatCurrency = (amount, currency) => {
    if (!amount) return 'N/A'
    const num = Number(amount)
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: currency || 'USD',
      maximumFractionDigits: 0,
    }).format(num)
  }

  if (loading) {
    return (
      <Container maxWidth="lg" sx={{ py: 10, textAlign: 'center' }}>
        <CircularProgress size={44} />
        <Typography variant="body1" color="text.secondary" sx={{ mt: 2 }}>
          Loading personnel records and compensation history...
        </Typography>
      </Container>
    )
  }

  if (error || !employee) {
    return (
      <Container maxWidth="lg" sx={{ py: 6 }}>
        <Button startIcon={<ArrowBackIcon />} onClick={() => navigate('/employees')} sx={{ mb: 3 }}>
          Back to Directory
        </Button>
        <Alert severity="error">{error || 'Employee record not found.'}</Alert>
      </Container>
    )
  }

  const activeSalary = employee.current_salary
  const salaryHistory = employee.salary_history || []

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      {/* Top Navigation */}
      <Button
        startIcon={<ArrowBackIcon />}
        onClick={() => navigate('/employees')}
        sx={{ mb: 3, textTransform: 'none' }}
      >
        Back to Employee Directory
      </Button>

      {successMessage && (
        <Alert severity="success" sx={{ mb: 3 }} onClose={() => setSuccessMessage(null)}>
          {successMessage}
        </Alert>
      )}

      {/* Employee Profile Header */}
      <Card sx={{ p: 3, mb: 4, bgcolor: '#111827', border: '1px solid #1f2937', borderRadius: 3 }}>
        <Stack direction={{ xs: 'column', md: 'row' }} justifyContent="space-between" alignItems={{ xs: 'flex-start', md: 'center' }} spacing={2}>
          <Box>
            <Stack direction="row" spacing={1.5} alignItems="center" sx={{ mb: 1 }}>
              <Typography variant="h4" fontWeight={800}>
                {employee.full_name}
              </Typography>
              <Chip label={employee.employee_code} sx={{ fontFamily: 'monospace', fontWeight: 700 }} />
              <Chip
                label={employee.employment_status.toUpperCase()}
                color={employee.employment_status === 'active' ? 'success' : 'warning'}
                size="small"
              />
            </Stack>
            <Typography variant="subtitle1" color="text.secondary">
              {employee.job_title} &bull; {employee.department?.name} ({employee.department?.code})
            </Typography>
          </Box>

          {isHrManager && (
            <Button
              variant="contained"
              color="primary"
              startIcon={<EditCalendarIcon />}
              onClick={handleOpenRevisionModal}
              sx={{ fontWeight: 700, textTransform: 'none', px: 3, py: 1.2 }}
            >
              Revise Salary
            </Button>
          )}
        </Stack>

        <Divider sx={{ my: 3, borderColor: '#1f2937' }} />

        {/* Info Grid */}
        <Grid container spacing={3}>
          <Grid xs={12} sm={6} md={3}>
            <Stack direction="row" spacing={1.5} alignItems="center">
              <PersonIcon color="action" />
              <Box>
                <Typography variant="caption" color="text.secondary">
                  EMAIL ADDRESS
                </Typography>
                <Typography variant="body2" fontWeight={600}>
                  {employee.email}
                </Typography>
              </Box>
            </Stack>
          </Grid>
          <Grid xs={12} sm={6} md={3}>
            <Stack direction="row" spacing={1.5} alignItems="center">
              <PublicIcon color="action" />
              <Box>
                <Typography variant="caption" color="text.secondary">
                  COUNTRY
                </Typography>
                <Typography variant="body2" fontWeight={600}>
                  {employee.country_code}
                </Typography>
              </Box>
            </Stack>
          </Grid>
          <Grid xs={12} sm={6} md={3}>
            <Stack direction="row" spacing={1.5} alignItems="center">
              <CalendarTodayIcon color="action" />
              <Box>
                <Typography variant="caption" color="text.secondary">
                  HIRE DATE
                </Typography>
                <Typography variant="body2" fontWeight={600}>
                  {employee.hire_date}
                </Typography>
              </Box>
            </Stack>
          </Grid>
          <Grid xs={12} sm={6} md={3}>
            <Stack direction="row" spacing={1.5} alignItems="center">
              <BusinessIcon color="action" />
              <Box>
                <Typography variant="caption" color="text.secondary">
                  DEPARTMENT
                </Typography>
                <Typography variant="body2" fontWeight={600}>
                  {employee.department?.name}
                </Typography>
              </Box>
            </Stack>
          </Grid>
        </Grid>
      </Card>

      {/* Active Compensation Card */}
      <Card sx={{ mb: 4, bgcolor: '#111827', border: '1px solid #1f2937', borderRadius: 3 }}>
        <CardContent sx={{ p: 3 }}>
          <Stack direction="row" spacing={1.5} alignItems="center" sx={{ mb: 2 }}>
            <MonetizationOnIcon color="success" />
            <Typography variant="h6" fontWeight={700}>
              Active Compensation
            </Typography>
          </Stack>

          {activeSalary ? (
            <Grid container spacing={3} alignItems="center">
              <Grid xs={12} md={4}>
                <Paper sx={{ p: 2.5, bgcolor: '#064e3b', border: '1px solid #059669', borderRadius: 2 }}>
                  <Typography variant="caption" sx={{ color: '#a7f3d0', fontWeight: 600 }}>
                    CURRENT BASE SALARY
                  </Typography>
                  <Typography variant="h4" fontWeight={800} sx={{ color: '#ecfdf5', mt: 0.5 }}>
                    {formatCurrency(activeSalary.amount, activeSalary.currency)}
                  </Typography>
                  <Typography variant="body2" sx={{ color: '#a7f3d0', mt: 0.5 }}>
                    {activeSalary.currency} &bull; {activeSalary.pay_frequency.toUpperCase()}
                  </Typography>
                </Paper>
              </Grid>

              <Grid xs={12} md={4}>
                <Box sx={{ p: 2, bgcolor: '#1f2937', borderRadius: 2 }}>
                  <Typography variant="caption" color="text.secondary">
                    EFFECTIVE PERIOD
                  </Typography>
                  <Typography variant="body1" fontWeight={700} sx={{ mt: 0.5 }}>
                    {activeSalary.effective_from} &rarr; Present
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    Open-ended active record
                  </Typography>
                </Box>
              </Grid>

              <Grid xs={12} md={4}>
                <Box sx={{ p: 2, bgcolor: '#1f2937', borderRadius: 2 }}>
                  <Typography variant="caption" color="text.secondary">
                    CHANGE REASON
                  </Typography>
                  <Typography variant="body1" fontWeight={700} sx={{ mt: 0.5 }}>
                    {activeSalary.change_reason || 'Initial Placement'}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    Recorded in compliance log
                  </Typography>
                </Box>
              </Grid>
            </Grid>
          ) : (
            <Alert severity="warning">No active salary record found for this employee.</Alert>
          )}
        </CardContent>
      </Card>

      {/* Historical Salary Timeline & Table */}
      <Card sx={{ bgcolor: '#111827', border: '1px solid #1f2937', borderRadius: 3 }}>
        <CardContent sx={{ p: 3 }}>
          <Stack direction="row" spacing={1.5} alignItems="center" sx={{ mb: 2 }}>
            <HistoryIcon color="primary" />
            <Typography variant="h6" fontWeight={700}>
              Effective-Dated Salary History ({salaryHistory.length} Revisions)
            </Typography>
          </Stack>

          <TableContainer>
            <Table>
              <TableHead sx={{ bgcolor: '#1f2937' }}>
                <TableRow>
                  <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Revision Amount</TableCell>
                  <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Currency</TableCell>
                  <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Effective From</TableCell>
                  <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Effective To</TableCell>
                  <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Frequency</TableCell>
                  <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Change Reason</TableCell>
                  <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Status</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {salaryHistory.map((rec) => (
                  <TableRow key={rec.id} hover>
                    <TableCell sx={{ fontWeight: 700, color: rec.effective_to ? 'text.primary' : '#34d399' }}>
                      {formatCurrency(rec.amount, rec.currency)}
                    </TableCell>
                    <TableCell sx={{ fontFamily: 'monospace' }}>{rec.currency}</TableCell>
                    <TableCell>{rec.effective_from}</TableCell>
                    <TableCell>{rec.effective_to || 'Present'}</TableCell>
                    <TableCell sx={{ textTransform: 'capitalize' }}>{rec.pay_frequency}</TableCell>
                    <TableCell>
                      <Chip label={rec.change_reason} size="small" variant="outlined" />
                    </TableCell>
                    <TableCell>
                      {rec.effective_to ? (
                        <Chip label="Historical" size="small" />
                      ) : (
                        <Chip label="Current Active" color="success" size="small" />
                      )}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* Salary Revision Dialog */}
      <Dialog open={openModal} onClose={handleCloseRevisionModal} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ bgcolor: '#111827', borderBottom: '1px solid #1f2937' }}>
          Revise Salary for {employee.full_name}
        </DialogTitle>
        <Box component="form" onSubmit={handleSubmitRevision} noValidate>
          <DialogContent sx={{ bgcolor: '#111827', py: 3 }}>
            {formError && (
              <Alert severity="error" sx={{ mb: 3 }}>
                {formError}
              </Alert>
            )}

            <Stack spacing={2.5}>
              <TextField
                required
                fullWidth
                label="New Salary Amount"
                type="number"
                value={revisionForm.amount}
                onChange={(e) => setRevisionForm({ ...revisionForm, amount: e.target.value })}
                helperText="Enter the total compensation amount for the specified frequency"
              />

              <Grid container spacing={2}>
                <Grid xs={6}>
                  <TextField
                    select
                    fullWidth
                    label="Currency"
                    value={revisionForm.currency}
                    onChange={(e) => setRevisionForm({ ...revisionForm, currency: e.target.value })}
                  >
                    {CURRENCIES.map((c) => (
                      <MenuItem key={c} value={c}>
                        {c}
                      </MenuItem>
                    ))}
                  </TextField>
                </Grid>
                <Grid xs={6}>
                  <TextField
                    select
                    fullWidth
                    label="Pay Frequency"
                    value={revisionForm.pay_frequency}
                    onChange={(e) => setRevisionForm({ ...revisionForm, pay_frequency: e.target.value })}
                  >
                    <MenuItem value="annual">Annual</MenuItem>
                    <MenuItem value="monthly">Monthly</MenuItem>
                    <MenuItem value="hourly">Hourly</MenuItem>
                  </TextField>
                </Grid>
              </Grid>

              <TextField
                required
                fullWidth
                label="Effective From Date"
                type="date"
                value={revisionForm.effective_from}
                onChange={(e) => setRevisionForm({ ...revisionForm, effective_from: e.target.value })}
                slotProps={{ inputLabel: { shrink: true } }}
                helperText={`Must be strictly after ${activeSalary?.effective_from || 'hire date'}`}
              />

              <TextField
                select
                fullWidth
                label="Change Reason"
                value={revisionForm.change_reason}
                onChange={(e) => setRevisionForm({ ...revisionForm, change_reason: e.target.value })}
              >
                {REASONS.map((r) => (
                  <MenuItem key={r.value} value={r.value}>
                    {r.label}
                  </MenuItem>
                ))}
              </TextField>
            </Stack>
          </DialogContent>
          <DialogActions sx={{ bgcolor: '#111827', borderTop: '1px solid #1f2937', p: 2 }}>
            <Button onClick={handleCloseRevisionModal} disabled={submitting}>
              Cancel
            </Button>
            <Button
              type="submit"
              variant="contained"
              color="primary"
              disabled={submitting}
              startIcon={submitting ? <CircularProgress size={16} /> : null}
            >
              {submitting ? 'Recording Revision...' : 'Save Salary Revision'}
            </Button>
          </DialogActions>
        </Box>
      </Dialog>
    </Container>
  )
}

import { useState } from 'react'
import {
  Dialog,
  DialogContent,
  DialogActions,
  Button,
  Box,
  Typography,
  Divider,
  Grid,
  Chip,
  Alert,
  CircularProgress,
} from '@mui/material'
import PrintIcon from '@mui/icons-material/Print'
import EmailIcon from '@mui/icons-material/Email'
import CheckCircleIcon from '@mui/icons-material/CheckCircle'
import apiClient from '../api/client'
import { formatINR } from '../utils/currency'

export default function PayslipModal({ open, onClose, payslip, onEmailSent }) {
  const [sendingEmail, setSendingEmail] = useState(false)
  const [emailSuccess, setEmailSuccess] = useState('')
  const [emailError, setEmailError] = useState('')

  if (!payslip) return null

  const handleSendEmail = async () => {
    setSendingEmail(true)
    setEmailSuccess('')
    setEmailError('')
    try {
      const res = await apiClient.post(`/api/v1/payslips/${payslip.id}/send_email`)
      setEmailSuccess(res.data.message || 'Payslip emailed successfully!')
      if (onEmailSent) onEmailSent(res.data.data)
    } catch (err) {
      setEmailError(err.response?.data?.error?.message || 'Failed to dispatch email')
    } finally {
      setSendingEmail(false)
    }
  }

  const handlePrint = () => {
    window.print()
  }

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogContent sx={{ p: { xs: 2, md: 4 }, bgcolor: '#0b0f19', color: '#f8fafc' }}>
        {/* Printable Section */}
        <Box className="printable-payslip" sx={{ bgcolor: '#0f172a', p: 3, borderRadius: 2, border: '1px solid #1e293b' }}>
          {/* Company Header */}
          <Box sx={{ borderBottom: '2px solid #38bdf8', pb: 2, mb: 3 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 1 }}>
              <Box>
                <Typography variant="h5" fontWeight={900} sx={{ color: '#38bdf8', letterSpacing: 0.5 }}>
                  ACME ENTERPRISE TECHNOLOGIES INDIA PVT. LTD.
                </Typography>
                <Typography variant="caption" sx={{ color: '#94a3b8', display: 'block' }}>
                  CIN: U72200KA2022PTC158912 | GSTIN: 29AAACA1234F1Z8 | TAN: BLRA09876C
                </Typography>
                <Typography variant="caption" sx={{ color: '#94a3b8', display: 'block' }}>
                  Prestige Tech Park, Outer Ring Road, Bengaluru, Karnataka &mdash; 560103
                </Typography>
              </Box>
              <Box sx={{ textAlign: { xs: 'left', sm: 'right' } }}>
                <Chip
                  label={`PAYSLIP &mdash; ${payslip.payroll_month}`}
                  color="primary"
                  sx={{ fontWeight: 800, fontSize: '0.8rem', letterSpacing: 0.5 }}
                />
                <Typography variant="caption" sx={{ display: 'block', mt: 0.5, color: '#94a3b8' }}>
                  {payslip.financial_year >= '2026' ? 'Tax Year' : 'Financial Year'}: <strong>{payslip.financial_year >= '2026' ? `Tax Year ${payslip.financial_year}` : `FY ${payslip.financial_year}`}</strong>
                </Typography>
              </Box>
            </Box>
          </Box>

          {/* Employee Metadata */}
          <Grid container spacing={2} sx={{ mb: 3, bgcolor: '#1e293b', p: 2, borderRadius: 1.5 }}>
            <Grid item xs={12} sm={6} md={3}>
              <Typography variant="caption" color="text.secondary">EMPLOYEE NAME</Typography>
              <Typography variant="body2" fontWeight={700}>{payslip.employee?.full_name}</Typography>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Typography variant="caption" color="text.secondary">EMPLOYEE CODE</Typography>
              <Typography variant="body2" fontWeight={700} sx={{ fontFamily: 'monospace', color: '#38bdf8' }}>
                {payslip.employee?.employee_code}
              </Typography>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Typography variant="caption" color="text.secondary">DEPARTMENT</Typography>
              <Typography variant="body2" fontWeight={600}>{payslip.employee?.department?.name || 'Engineering'}</Typography>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Typography variant="caption" color="text.secondary">EMAIL ADDRESS</Typography>
              <Typography variant="body2" fontWeight={500}>{payslip.employee?.email}</Typography>
            </Grid>

            <Grid item xs={12} sm={6} md={3}>
              <Typography variant="caption" color="text.secondary">DAYS WORKED</Typography>
              <Typography variant="body2" fontWeight={700}>{payslip.working_days} Days</Typography>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Typography variant="caption" color="text.secondary">PAID LEAVES</Typography>
              <Typography variant="body2" fontWeight={700}>{payslip.paid_leaves} Days</Typography>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Typography variant="caption" color="text.secondary">LOSS OF PAY (LOP)</Typography>
              <Typography variant="body2" fontWeight={700} color={payslip.lop_days > 0 ? 'error.main' : 'text.primary'}>
                {payslip.lop_days} Days
              </Typography>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Typography variant="caption" color="text.secondary">TAX REGIME</Typography>
              <Typography variant="body2" fontWeight={700} color="success.main">New Regime (FY 24-25)</Typography>
            </Grid>
          </Grid>

          {/* Earnings & Deductions Tables */}
          <Grid container spacing={3} sx={{ mb: 3 }}>
            {/* Earnings Column */}
            <Grid item xs={12} md={6}>
              <Box sx={{ border: '1px solid #334155', borderRadius: 1.5, overflow: 'hidden' }}>
                <Box sx={{ bgcolor: '#1e293b', p: 1.5, borderBottom: '1px solid #334155' }}>
                  <Typography variant="subtitle2" fontWeight={700} color="#38bdf8">
                    EARNINGS (CREDIT)
                  </Typography>
                </Box>
                <Box sx={{ p: 2 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.8 }}>
                    <Typography variant="body2">Basic Salary (50%)</Typography>
                    <Typography variant="body2" fontWeight={600}>{formatINR(payslip.basic_pay)}</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.8 }}>
                    <Typography variant="body2">House Rent Allowance (HRA)</Typography>
                    <Typography variant="body2" fontWeight={600}>{formatINR(payslip.hra)}</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.8 }}>
                    <Typography variant="body2">Special Allowance</Typography>
                    <Typography variant="body2" fontWeight={600}>{formatINR(payslip.special_allowance)}</Typography>
                  </Box>
                  {payslip.diwali_bonus > 0 && (
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.8, bgcolor: 'rgba(245, 158, 11, 0.1)', px: 1, borderRadius: 1 }}>
                      <Typography variant="body2" fontWeight={700} color="#f59e0b">
                        🪔 Diwali Festive Bonus
                      </Typography>
                      <Typography variant="body2" fontWeight={700} color="#f59e0b">
                        {formatINR(payslip.diwali_bonus)}
                      </Typography>
                    </Box>
                  )}
                  <Divider sx={{ my: 1.5, borderColor: '#334155' }} />
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.5 }}>
                    <Typography variant="subtitle2" fontWeight={800}>Gross Earnings</Typography>
                    <Typography variant="subtitle2" fontWeight={800} color="#34d399">
                      {formatINR(payslip.gross_earnings)}
                    </Typography>
                  </Box>
                </Box>
              </Box>
            </Grid>

            {/* Deductions Column */}
            <Grid item xs={12} md={6}>
              <Box sx={{ border: '1px solid #334155', borderRadius: 1.5, overflow: 'hidden' }}>
                <Box sx={{ bgcolor: '#1e293b', p: 1.5, borderBottom: '1px solid #334155' }}>
                  <Typography variant="subtitle2" fontWeight={700} color="#f87171">
                    STATUTORY DEDUCTIONS (DEBIT)
                  </Typography>
                </Box>
                <Box sx={{ p: 2 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.8 }}>
                    <Typography variant="body2">Provident Fund (EPF 12%)</Typography>
                    <Typography variant="body2" fontWeight={600}>{formatINR(payslip.epf_deduction)}</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.8 }}>
                    <Typography variant="body2">Professional Tax (PT)</Typography>
                    <Typography variant="body2" fontWeight={600}>{formatINR(payslip.pt_deduction)}</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.8 }}>
                    <Typography variant="body2">Income Tax (TDS - New Regime)</Typography>
                    <Typography variant="body2" fontWeight={600}>{formatINR(payslip.tds_tax_deduction)}</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.8 }}>
                    <Typography variant="body2">Leave Loss of Pay (LOP)</Typography>
                    <Typography variant="body2" fontWeight={600} color={payslip.lop_deduction > 0 ? 'error.main' : 'text.primary'}>
                      {formatINR(payslip.lop_deduction)}
                    </Typography>
                  </Box>
                  <Divider sx={{ my: 1.5, borderColor: '#334155' }} />
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.5 }}>
                    <Typography variant="subtitle2" fontWeight={800}>Total Deductions</Typography>
                    <Typography variant="subtitle2" fontWeight={800} color="#f87171">
                      {formatINR(payslip.total_deductions)}
                    </Typography>
                  </Box>
                </Box>
              </Box>
            </Grid>
          </Grid>

          {/* Net Take-Home Highlight Banner */}
          <Box sx={{ bgcolor: '#064e3b', border: '1px solid #059669', p: 3, borderRadius: 2, textAlign: 'center', mb: 2 }}>
            <Typography variant="caption" sx={{ color: '#a7f3d0', fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase' }}>
              NET DISBURSED TAKE-HOME SALARY
            </Typography>
            <Typography variant="h3" fontWeight={900} sx={{ color: '#ecfdf5', my: 1 }}>
              {formatINR(payslip.net_pay)}
            </Typography>
            <Typography variant="body2" sx={{ color: '#a7f3d0', fontStyle: 'italic', fontWeight: 500 }}>
              {payslip.net_pay_in_words}
            </Typography>
          </Box>

          <Box sx={{ textAlign: 'center', pt: 1 }}>
            <Typography variant="caption" color="text.secondary">
              Note: Income tax is calculated under Indian Government New Tax Regime with ₹75,000 Standard Deduction and Section 87A rebate.
            </Typography>
          </Box>
        </Box>

        {/* Action Alerts */}
        {emailSuccess && (
          <Alert severity="success" sx={{ mt: 2 }} icon={<CheckCircleIcon />}>
            {emailSuccess}
          </Alert>
        )}
        {emailError && (
          <Alert severity="error" sx={{ mt: 2 }}>
            {emailError}
          </Alert>
        )}
      </DialogContent>

      <DialogActions sx={{ p: 2.5, bgcolor: '#0b0f19', borderTop: '1px solid #1e293b' }} className="no-print">
        <Button onClick={onClose} sx={{ color: 'text.secondary' }}>
          Close
        </Button>
        <Button
          variant="outlined"
          startIcon={<PrintIcon />}
          onClick={handlePrint}
          sx={{ textTransform: 'none', fontWeight: 600, borderColor: '#334155' }}
        >
          Print Payslip
        </Button>
        <Button
          variant="contained"
          color="primary"
          startIcon={sendingEmail ? <CircularProgress size={16} color="inherit" /> : <EmailIcon />}
          onClick={handleSendEmail}
          disabled={sendingEmail}
          sx={{ textTransform: 'none', fontWeight: 700 }}
        >
          {sendingEmail ? 'Dispatching Email...' : 'Send Payslip via Email'}
        </Button>
      </DialogActions>
    </Dialog>
  )
}

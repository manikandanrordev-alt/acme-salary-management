// Indian Rupee (₹) Currency and Number Formatter

export function formatINR(amount, options = {}) {
  if (amount === null || amount === undefined || isNaN(Number(amount))) {
    return '₹0.00'
  }

  const num = Number(amount)
  const maxDecimals = options.decimals !== undefined ? options.decimals : 2

  // Intl Indian currency format
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: maxDecimals,
    minimumFractionDigits: options.decimals !== undefined ? options.decimals : 0,
  }).format(num)
}

export function formatLakhsCrores(amount) {
  if (amount === null || amount === undefined || isNaN(Number(amount))) {
    return '₹0'
  }

  const num = Math.abs(Number(amount))
  if (num >= 10000000) {
    return `₹${(num / 10000000).toFixed(2)} Cr`
  }
  if (num >= 100000) {
    return `₹${(num / 100000).toFixed(2)} L`
  }
  return formatINR(amount, { decimals: 0 })
}

export function numberToWordsINR(amount) {
  const num = Math.floor(Math.abs(Number(amount) || 0))
  if (num === 0) return 'Zero Rupees Only'

  const units = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
    'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen']
  const tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety']

  const convert = (n) => {
    if (n < 20) return units[n]
    if (n < 100) return `${tens[Math.floor(n / 10)]} ${units[n % 10]}`.trim()
    if (n < 1000) return `${units[Math.floor(n / 100)]} Hundred ${convert(n % 100)}`.trim()
    if (n < 100000) return `${convert(Math.floor(n / 1000))} Thousand ${convert(n % 1000)}`.trim()
    if (n < 10000000) return `${convert(Math.floor(n / 100000))} Lakh ${convert(n % 100000)}`.trim()
    return `${convert(Math.floor(n / 10000000))} Crore ${convert(n % 10000000)}`.trim()
  }

  return `${convert(num)} Rupees Only`
}

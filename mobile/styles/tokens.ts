/**
 * Design tokens for React Native (mobile)
 *
 * Virent style guide (BarqScoot-inspired):
 *   - Light theme by default, dark optional
 *   - Primary teal-blue #3489FF
 *   - Plus Jakarta Sans (web), system font (RN)
 *   - 16 px radius on cards, 12 px on buttons
 *   - Subtle shadows (0.05 black, blur 10, offset 0,2)
 *   - Material icons only (no emoji)
 */

import { Platform } from 'react-native';

export const spacing = {
  s0: 0, s0_5: 2, s1: 4, s2: 8, s3: 12, s4: 16, s5: 20, s6: 24,
  s8: 32, s10: 40, s12: 48, s16: 64, s20: 80, s24: 96,
};

export const typography = {
  fontFamily: Platform.select({
    ios: 'PlusJakartaSans-SemiBold',
    android: 'sans-serif-medium',
    default: 'System',
  }),
  fontFamilyRegular: Platform.select({
    ios: 'PlusJakartaSans-Regular',
    android: 'sans-serif',
    default: 'System',
  }),
  size: {
    tiny: 11, xs: 12, sm: 14, md: 16, lg: 18, xl: 20,
    '2xl': 24, '3xl': 28, '4xl': 32, '5xl': 40, '6xl': 56,
  },
  weight: {
    regular: '400' as const, medium: '500' as const,
    semibold: '600' as const, bold: '700' as const,
  },
};

export const colors = {
  white: '#ffffff',
  neutral: {
    50: '#f9fafb', 100: '#f3f4f6', 200: '#e5e7eb', 300: '#d1d5db',
    400: '#9ca3af', 500: '#6b7280', 600: '#4b5563', 700: '#374151',
    800: '#1f2937', 900: '#111827', 950: '#030712',
  },
  primary: {
    50: '#eff6ff', 100: '#dbeafe', 200: '#bfdbfe', 300: '#93c5fd',
    400: '#60a5fa', 500: '#3489FF', 600: '#2a75e0', 700: '#1e51a8',
    800: '#1e40af', 900: '#1e3a8a',
  },
  success: '#16a34a', successBg: '#dcfce7',
  warning: '#d97706', warningBg: '#fef3c7',
  danger: '#dc2626', dangerBg: '#fee2e2',
  info: '#0284c7', infoBg: '#e0f2fe',
  bg: '#ffffff', bgAlt: '#f9fafb',
  surface: '#ffffff', surfaceAlt: '#f3f4f6',
  border: '#e5e7eb', borderStrong: '#d1d5db',
  textPrimary: '#111827', textSecondary: '#4b5563', textMuted: '#9ca3af',
  textOnPrimary: '#ffffff',
};

export const radius = {
  none: 0, sm: 4, md: 8, lg: 12, xl: 16, '2xl': 20, full: 999,
};

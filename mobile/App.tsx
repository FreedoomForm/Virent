/**
 * App.tsx — Virent mobile app entry point
 *
 * Bottom-tab navigation: Map | Trips | Wallet | Settings
 * Center FAB: QR scanner
 *
 * Style: BarqScoot-inspired light theme (Plus Jakarta Sans, teal-blue #3489FF)
 * Icons: @expo/vector-icons (Ionicons) — no emoji
 */

import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { SafeAreaView, View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { Ionicons } from '@expo/vector-icons';

import { colors, typography, spacing } from './styles/tokens';

const Tab = createBottomTabNavigator();
const Stack = createNativeStackNavigator();

function MapPlaceholder() {
  return (
    <View style={styles.placeholder}>
      <Ionicons name="map" size={64} color={colors.textMuted} />
      <Text style={styles.placeholderText}>Map</Text>
      <Text style={styles.placeholderSub}>Scooter discovery</Text>
    </View>
  );
}

function TripsPlaceholder() {
  return (
    <View style={styles.placeholder}>
      <Ionicons name="route" size={64} color={colors.textMuted} />
      <Text style={styles.placeholderText}>Trips</Text>
      <Text style={styles.placeholderSub}>Trip history</Text>
    </View>
  );
}

function WalletPlaceholder() {
  return (
    <View style={styles.placeholder}>
      <Ionicons name="wallet" size={64} color={colors.textMuted} />
      <Text style={styles.placeholderText}>Wallet</Text>
      <Text style={styles.placeholderSub}>Balance and top-up</Text>
    </View>
  );
}

function SettingsPlaceholder() {
  return (
    <View style={styles.placeholder}>
      <Ionicons name="settings" size={64} color={colors.textMuted} />
      <Text style={styles.placeholderText}>Settings</Text>
      <Text style={styles.placeholderSub}>Profile and preferences</Text>
    </View>
  );
}

export default function App() {
  return (
    <>
      <StatusBar style="dark" />
      <NavigationContainer>
        <Tab.Navigator
          screenOptions={{
            headerShown: false,
            tabBarActiveTintColor: colors.primary[500],
            tabBarInactiveTintColor: colors.textMuted,
            tabBarStyle: {
              height: 60,
              paddingBottom: 8,
              paddingTop: 8,
              backgroundColor: colors.surface,
              borderTopColor: colors.border,
              borderTopWidth: 1,
            },
            tabBarLabelStyle: {
              fontSize: typography.size.xs,
              fontFamily: typography.fontFamily,
            },
          }}
        >
          <Tab.Screen name="Map" component={MapPlaceholder}
            options={{
              tabBarLabel: 'Map',
              tabBarIcon: ({ color, size }) => <Ionicons name="map" size={size} color={color} />,
            }} />
          <Tab.Screen name="Trips" component={TripsPlaceholder}
            options={{
              tabBarLabel: 'Trips',
              tabBarIcon: ({ color, size }) => <Ionicons name="route" size={size} color={color} />,
            }} />
          <Tab.Screen name="Wallet" component={WalletPlaceholder}
            options={{
              tabBarLabel: 'Wallet',
              tabBarIcon: ({ color, size }) => <Ionicons name="wallet" size={size} color={color} />,
            }} />
          <Tab.Screen name="Settings" component={SettingsPlaceholder}
            options={{
              tabBarLabel: 'Settings',
              tabBarIcon: ({ color, size }) => <Ionicons name="settings" size={size} color={color} />,
            }} />
        </Tab.Navigator>
      </NavigationContainer>
    </>
  );
}

const styles = StyleSheet.create({
  placeholder: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.bg,
    padding: spacing.s4,
  },
  placeholderText: {
    fontSize: typography.size['2xl'],
    fontWeight: '700' as const,
    color: colors.textPrimary,
    fontFamily: typography.fontFamily,
    marginTop: spacing.s4,
  },
  placeholderSub: {
    fontSize: typography.size.sm,
    color: colors.textMuted,
    fontFamily: typography.fontFamily,
    marginTop: spacing.s1,
  },
});

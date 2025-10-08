/**
 * Service Token Storage Utility
 *
 * Provides secure storage and retrieval of service authentication tokens
 * with automatic 30-day expiration and user-controlled enable/disable.
 */

const STORAGE_PREFIX = 'service_token_';
const SETTINGS_KEY = 'token_storage_enabled';
const TOKEN_EXPIRY_DAYS = 30;

export interface StoredToken {
  token: string;
  serviceId: number;
  serviceName: string;
  storedAt: number; // timestamp in milliseconds
  expiresAt: number; // timestamp in milliseconds
}

/**
 * Simple base64 encoding for basic obfuscation
 * Note: This is NOT encryption, just obfuscation to prevent casual viewing
 */
const encode = (str: string): string => {
  try {
    return btoa(encodeURIComponent(str));
  } catch (e) {
    console.error('Failed to encode token:', e);
    return str;
  }
};

const decode = (str: string): string => {
  try {
    return decodeURIComponent(atob(str));
  } catch (e) {
    console.error('Failed to decode token:', e);
    return str;
  }
};

/**
 * Check if token storage feature is enabled by user
 */
export const isTokenStorageEnabled = (): boolean => {
  try {
    const enabled = localStorage.getItem(SETTINGS_KEY);
    return enabled === 'true';
  } catch (e) {
    console.error('Failed to check token storage setting:', e);
    return false;
  }
};

/**
 * Enable or disable token storage feature
 */
export const setTokenStorageEnabled = (enabled: boolean): void => {
  try {
    localStorage.setItem(SETTINGS_KEY, enabled.toString());

    // If disabling, clear all stored tokens
    if (!enabled) {
      clearAllTokens();
    }
  } catch (e) {
    console.error('Failed to update token storage setting:', e);
  }
};

/**
 * Save a service token with 30-day expiration
 */
export const saveServiceToken = (
  serviceId: number,
  serviceName: string,
  token: string
): boolean => {
  // Only save if feature is enabled
  if (!isTokenStorageEnabled()) {
    return false;
  }

  try {
    const now = Date.now();
    const expiresAt = now + (TOKEN_EXPIRY_DAYS * 24 * 60 * 60 * 1000);

    const storedToken: StoredToken = {
      token: encode(token),
      serviceId,
      serviceName,
      storedAt: now,
      expiresAt
    };

    const key = `${STORAGE_PREFIX}${serviceId}`;
    localStorage.setItem(key, JSON.stringify(storedToken));

    return true;
  } catch (e) {
    console.error('Failed to save service token:', e);
    return false;
  }
};

/**
 * Retrieve a service token (returns null if expired or not found)
 */
export const getServiceToken = (serviceId: number): string | null => {
  // Only retrieve if feature is enabled
  if (!isTokenStorageEnabled()) {
    return null;
  }

  try {
    const key = `${STORAGE_PREFIX}${serviceId}`;
    const stored = localStorage.getItem(key);

    if (!stored) {
      return null;
    }

    const tokenData: StoredToken = JSON.parse(stored);

    // Check if token has expired
    if (Date.now() > tokenData.expiresAt) {
      // Remove expired token
      localStorage.removeItem(key);
      return null;
    }

    return decode(tokenData.token);
  } catch (e) {
    console.error('Failed to retrieve service token:', e);
    return null;
  }
};

/**
 * Get token metadata (without decoding the actual token)
 */
export const getTokenMetadata = (serviceId: number): Omit<StoredToken, 'token'> | null => {
  if (!isTokenStorageEnabled()) {
    return null;
  }

  try {
    const key = `${STORAGE_PREFIX}${serviceId}`;
    const stored = localStorage.getItem(key);

    if (!stored) {
      return null;
    }

    const tokenData: StoredToken = JSON.parse(stored);

    // Check if expired
    if (Date.now() > tokenData.expiresAt) {
      localStorage.removeItem(key);
      return null;
    }

    const { token, ...metadata } = tokenData;
    return metadata;
  } catch (e) {
    console.error('Failed to retrieve token metadata:', e);
    return null;
  }
};

/**
 * Remove a specific service token
 */
export const removeServiceToken = (serviceId: number): void => {
  try {
    const key = `${STORAGE_PREFIX}${serviceId}`;
    localStorage.removeItem(key);
  } catch (e) {
    console.error('Failed to remove service token:', e);
  }
};

/**
 * Clear all stored service tokens
 */
export const clearAllTokens = (): void => {
  try {
    const keys = Object.keys(localStorage);
    keys.forEach(key => {
      if (key.startsWith(STORAGE_PREFIX)) {
        localStorage.removeItem(key);
      }
    });
  } catch (e) {
    console.error('Failed to clear all tokens:', e);
  }
};

/**
 * Get all stored tokens (for management purposes)
 */
export const getAllStoredTokens = (): Array<Omit<StoredToken, 'token'>> => {
  if (!isTokenStorageEnabled()) {
    return [];
  }

  try {
    const keys = Object.keys(localStorage);
    const tokens: Array<Omit<StoredToken, 'token'>> = [];

    keys.forEach(key => {
      if (key.startsWith(STORAGE_PREFIX)) {
        try {
          const stored = localStorage.getItem(key);
          if (stored) {
            const tokenData: StoredToken = JSON.parse(stored);

            // Check if expired
            if (Date.now() > tokenData.expiresAt) {
              localStorage.removeItem(key);
            } else {
              const { token, ...metadata } = tokenData;
              tokens.push(metadata);
            }
          }
        } catch (e) {
          // Skip invalid entries
        }
      }
    });

    return tokens;
  } catch (e) {
    console.error('Failed to get all stored tokens:', e);
    return [];
  }
};

/**
 * Get days until token expiration
 */
export const getDaysUntilExpiration = (serviceId: number): number | null => {
  const metadata = getTokenMetadata(serviceId);
  if (!metadata) {
    return null;
  }

  const now = Date.now();
  const daysRemaining = Math.ceil((metadata.expiresAt - now) / (24 * 60 * 60 * 1000));
  return daysRemaining;
};

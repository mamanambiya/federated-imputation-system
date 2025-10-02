// Global setup for Playwright tests
// This runs once before all tests

const { chromium } = require('@playwright/test');
const fs = require('fs');
const path = require('path');

async function globalSetup(config) {
  console.log('🚀 Starting global setup for Federated Genomic Imputation Platform tests...');
  
  // Create necessary directories
  const dirs = [
    'tests/screenshots',
    'tests/test-results',
    'tests/playwright-report'
  ];
  
  dirs.forEach(dir => {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
      console.log(`📁 Created directory: ${dir}`);
    }
  });
  
  // Wait for services to be ready
  console.log('⏳ Waiting for services to be ready...');
  
  const browser = await chromium.launch();
  const page = await browser.newPage();
  
  try {
    // Check if frontend is ready
    let frontendReady = false;
    for (let i = 0; i < 30; i++) {
      try {
        const response = await page.goto('http://localhost:3000', { timeout: 5000 });
        if (response && response.status() === 200) {
          frontendReady = true;
          console.log('✅ Frontend is ready');
          break;
        }
      } catch (error) {
        console.log(`⏳ Waiting for frontend... (attempt ${i + 1}/30)`);
        await page.waitForTimeout(2000);
      }
    }
    
    if (!frontendReady) {
      throw new Error('Frontend failed to start within timeout');
    }
    
    // Check if backend API is ready
    let backendReady = false;
    for (let i = 0; i < 30; i++) {
      try {
        const response = await page.request.get('http://localhost:8000/api/services/');
        if (response.status() === 200) {
          backendReady = true;
          console.log('✅ Backend API is ready');
          break;
        }
      } catch (error) {
        console.log(`⏳ Waiting for backend API... (attempt ${i + 1}/30)`);
        await page.waitForTimeout(2000);
      }
    }
    
    if (!backendReady) {
      throw new Error('Backend API failed to start within timeout');
    }
    
    // Verify database has data
    try {
      const servicesResponse = await page.request.get('http://localhost:8000/api/services/');
      const servicesData = await servicesResponse.json();
      const serviceCount = servicesData.count || servicesData.length || 0;
      
      if (serviceCount > 0) {
        console.log(`✅ Database has ${serviceCount} services`);
      } else {
        console.log('⚠️ Warning: No services found in database');
      }
    } catch (error) {
      console.log('⚠️ Warning: Could not verify database data');
    }
    
    // Create test user if needed
    try {
      const loginResponse = await page.request.post('http://localhost:8000/api/auth/login/', {
        data: {
          username: 'test_user',
          password: 'test_password'
        }
      });
      
      if (loginResponse.status() === 200) {
        console.log('✅ Test user is available');
      } else {
        console.log('⚠️ Warning: Test user login failed');
      }
    } catch (error) {
      console.log('⚠️ Warning: Could not verify test user');
    }
    
    console.log('🎉 Global setup completed successfully!');
    
  } catch (error) {
    console.error('❌ Global setup failed:', error.message);
    throw error;
  } finally {
    await browser.close();
  }
}

module.exports = globalSetup;

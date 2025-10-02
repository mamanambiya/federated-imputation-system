// Global teardown for Playwright tests
// This runs once after all tests complete

const fs = require('fs');
const path = require('path');

async function globalTeardown(config) {
  console.log('🧹 Starting global teardown...');
  
  try {
    // Generate test summary
    const resultsPath = 'tests/playwright-results.json';
    if (fs.existsSync(resultsPath)) {
      const results = JSON.parse(fs.readFileSync(resultsPath, 'utf8'));
      
      console.log('\n📊 Test Results Summary:');
      console.log(`Total tests: ${results.stats?.total || 'Unknown'}`);
      console.log(`Passed: ${results.stats?.passed || 'Unknown'}`);
      console.log(`Failed: ${results.stats?.failed || 'Unknown'}`);
      console.log(`Skipped: ${results.stats?.skipped || 'Unknown'}`);
      
      if (results.stats?.failed > 0) {
        console.log('\n❌ Failed tests:');
        results.suites?.forEach(suite => {
          suite.specs?.forEach(spec => {
            spec.tests?.forEach(test => {
              if (test.results?.some(result => result.status === 'failed')) {
                console.log(`  - ${spec.title}: ${test.title}`);
              }
            });
          });
        });
      }
    }
    
    // Clean up temporary files if needed
    const tempFiles = [
      'tests/temp',
      'tests/downloads'
    ];
    
    tempFiles.forEach(file => {
      if (fs.existsSync(file)) {
        fs.rmSync(file, { recursive: true, force: true });
        console.log(`🗑️ Cleaned up: ${file}`);
      }
    });
    
    console.log('\n📁 Test artifacts saved to:');
    console.log('  - Screenshots: tests/screenshots/');
    console.log('  - HTML Report: tests/playwright-report/');
    console.log('  - Test Results: tests/test-results/');
    
    console.log('\n✅ Global teardown completed successfully!');
    
  } catch (error) {
    console.error('❌ Global teardown failed:', error.message);
  }
}

module.exports = globalTeardown;

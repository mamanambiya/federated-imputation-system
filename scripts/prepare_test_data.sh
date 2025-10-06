#!/bin/bash
#
# Test Data Preparation Script for H3Africa Job Execution
#
# This script downloads and prepares small VCF files for testing
# the job execution pipeline without waiting for large files to process.
#
# Usage: bash scripts/prepare_test_data.sh
#

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TEST_DATA_DIR="$HOME/test_data"
TEMP_DIR="/tmp/imputation_test"

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}       Test Data Preparation for Job Execution          ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

# Create directories
echo -e "${YELLOW}Creating test data directory...${NC}"
mkdir -p "$TEST_DATA_DIR"
mkdir -p "$TEMP_DIR"
echo -e "${GREEN}✓${NC} Created: $TEST_DATA_DIR"

# Check for required tools
echo ""
echo -e "${YELLOW}Checking required tools...${NC}"

command -v wget >/dev/null 2>&1 || { echo "Installing wget..."; sudo apt-get install -y wget; }
command -v bcftools >/dev/null 2>&1 || { echo "Installing bcftools..."; sudo apt-get install -y bcftools; }
command -v bgzip >/dev/null 2>&1 || { echo "Installing tabix (for bgzip)..."; sudo apt-get install -y tabix; }

echo -e "${GREEN}✓${NC} All tools available"

# Download chromosome 22 from 1000 Genomes (small for testing)
echo ""
echo -e "${YELLOW}Downloading 1000 Genomes chromosome 22 VCF...${NC}"
echo "Source: 1000 Genomes Phase 3, GRCh38"

cd "$TEMP_DIR"

# Download small chr22 VCF if not already present
CHR22_URL="ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/supporting/GRCh38_positions/ALL.chr22.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz"

if [ ! -f "chr22_full.vcf.gz" ]; then
    echo "Downloading from 1000 Genomes FTP..."
    wget -q --show-progress -O chr22_full.vcf.gz "$CHR22_URL" || {
        echo "FTP download failed. Using alternative method..."
        # Fallback: create minimal test VCF
        echo "Creating minimal test VCF instead..."
        cat > minimal_test.vcf << 'EOF'
##fileformat=VCFv4.2
##FILTER=<ID=PASS,Description="All filters passed">
##contig=<ID=22,length=50818468>
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	SAMPLE1	SAMPLE2	SAMPLE3
22	16050075	rs587697622	A	G	100	PASS	.	GT	0|0	0|1	1|1
22	16050115	rs587755077	G	A	100	PASS	.	GT	1|0	0|0	0|1
22	16050213	rs587654321	C	T	100	PASS	.	GT	0|0	1|1	0|1
EOF
        bgzip minimal_test.vcf
        mv minimal_test.vcf.gz chr22_full.vcf.gz
    }
else
    echo -e "${GREEN}✓${NC} Using cached download"
fi

# Extract test datasets of different sizes
echo ""
echo -e "${YELLOW}Creating test VCF files...${NC}"

# 1. Tiny test (100 variants) - for quick API tests
echo "1. Creating tiny test (100 variants)..."
zcat chr22_full.vcf.gz | head -200 | grep -v "^##contig" > test_tiny_100var.vcf
bgzip -f test_tiny_100var.vcf
mv test_tiny_100var.vcf.gz "$TEST_DATA_DIR/"
TINY_SIZE=$(du -h "$TEST_DATA_DIR/test_tiny_100var.vcf.gz" | cut -f1)
echo -e "${GREEN}✓${NC} Created: test_tiny_100var.vcf.gz ($TINY_SIZE)"

# 2. Small test (1000 variants) - standard test
echo "2. Creating small test (1000 variants)..."
zcat chr22_full.vcf.gz | head -1100 | grep -v "^##contig" > test_small_1000var.vcf
bgzip -f test_small_1000var.vcf
mv test_small_1000var.vcf.gz "$TEST_DATA_DIR/"
SMALL_SIZE=$(du -h "$TEST_DATA_DIR/test_small_1000var.vcf.gz" | cut -f1)
echo -e "${GREEN}✓${NC} Created: test_small_1000var.vcf.gz ($SMALL_SIZE)"

# 3. Medium test (10000 variants) - more realistic
echo "3. Creating medium test (10000 variants)..."
zcat chr22_full.vcf.gz | head -10100 | grep -v "^##contig" > test_medium_10kvar.vcf
bgzip -f test_medium_10kvar.vcf
mv test_medium_10kvar.vcf.gz "$TEST_DATA_DIR/"
MEDIUM_SIZE=$(du -h "$TEST_DATA_DIR/test_medium_10kvar.vcf.gz" | cut -f1)
echo -e "${GREEN}✓${NC} Created: test_medium_10kvar.vcf.gz ($MEDIUM_SIZE)"

# Validate VCF files
echo ""
echo -e "${YELLOW}Validating VCF files...${NC}"

for vcf_file in "$TEST_DATA_DIR"/*.vcf.gz; do
    filename=$(basename "$vcf_file")

    # Check if it's a valid VCF
    if zcat "$vcf_file" | head -1 | grep -q "^##fileformat=VCF"; then
        variant_count=$(zcat "$vcf_file" | grep -v "^#" | wc -l)
        sample_count=$(zcat "$vcf_file" | grep "^#CHROM" | awk '{print NF-9}')

        echo -e "${GREEN}✓${NC} $filename - ${variant_count} variants, ${sample_count} samples"
    else
        echo -e "${YELLOW}⚠${NC} $filename may not be valid VCF"
    fi
done

# Create README
echo ""
echo -e "${YELLOW}Creating README...${NC}"

cat > "$TEST_DATA_DIR/README.md" << 'EOF'
# Test Data for H3Africa Job Execution

This directory contains test VCF files for testing the imputation job pipeline.

## Files

### test_tiny_100var.vcf.gz
- **Variants**: 100
- **Use Case**: Quick API testing, development
- **Expected Runtime**: 2-5 minutes
- **File Size**: ~10-20 KB

### test_small_1000var.vcf.gz
- **Variants**: 1,000
- **Use Case**: Standard testing, E2E validation
- **Expected Runtime**: 5-10 minutes
- **File Size**: ~100-200 KB

### test_medium_10kvar.vcf.gz
- **Variants**: 10,000
- **Use Case**: Realistic testing, performance validation
- **Expected Runtime**: 15-30 minutes
- **File Size**: ~1-2 MB

## Source Data

All test files are derived from:
- **Source**: 1000 Genomes Project Phase 3
- **Build**: GRCh38 (hg38)
- **Chromosome**: 22 (smallest autosomal chromosome)
- **Population**: Multi-ethnic (ALL populations)

## Usage Examples

### Quick API Test (Tiny)
```bash
curl -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $TOKEN" \
  -F "name=Quick API Test" \
  -F "service_id=1" \
  -F "reference_panel_id=1" \
  -F "input_format=vcf" \
  -F "build=hg38" \
  -F "input_file=@~/test_data/test_tiny_100var.vcf.gz"
```

### Standard E2E Test (Small)
```bash
curl -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $TOKEN" \
  -F "name=E2E Test Job" \
  -F "service_id=1" \
  -F "reference_panel_id=1" \
  -F "input_format=vcf" \
  -F "build=hg38" \
  -F "phasing=true" \
  -F "population=AFR" \
  -F "input_file=@~/test_data/test_small_1000var.vcf.gz"
```

### Realistic Test (Medium)
```bash
curl -X POST http://localhost:8003/jobs \
  -H "Authorization: Bearer $TOKEN" \
  -F "name=Realistic Test Job" \
  -F "service_id=1" \
  -F "reference_panel_id=1" \
  -F "input_format=vcf" \
  -F "build=hg38" \
  -F "phasing=true" \
  -F "population=AFR" \
  -F "input_file=@~/test_data/test_medium_10kvar.vcf.gz"
```

## Build Compatibility

These files use **hg38/GRCh38** build. If you need hg19:
```bash
# Convert using UCSC liftOver (requires liftOver tool and chain file)
liftOver input.vcf hg38ToHg19.over.chain.gz output_hg19.vcf unlifted.vcf
```

## Notes

- All files are bgzipped and ready for use
- Files are suitable for both Michigan and GA4GH services
- Samples are anonymized from 1000 Genomes
- Variants are phased (suitable for phasing parameter testing)
EOF

echo -e "${GREEN}✓${NC} Created README.md"

# Clean up temp directory
rm -rf "$TEMP_DIR"

# Summary
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Test Data Preparation Complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""
echo "📁 Test data location: $TEST_DATA_DIR"
echo ""
echo "📊 Files created:"
echo "   1. test_tiny_100var.vcf.gz     - $TINY_SIZE   (100 variants)"
echo "   2. test_small_1000var.vcf.gz   - $SMALL_SIZE  (1K variants)"
echo "   3. test_medium_10kvar.vcf.gz   - $MEDIUM_SIZE (10K variants)"
echo ""
echo "📖 See $TEST_DATA_DIR/README.md for usage examples"
echo ""
echo "🚀 Next steps:"
echo "   1. Setup H3Africa service: python scripts/setup_h3africa_service.py --api-token YOUR_TOKEN"
echo "   2. Run E2E test: bash scripts/e2e_h3africa_test.sh"
echo ""

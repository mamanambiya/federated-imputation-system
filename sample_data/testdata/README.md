# Test VCF Files for Imputation

This directory contains test VCF files for quick testing of the imputation platform.

## Available Test Files

| File | Variants | Size | Estimated Processing Time |
|------|----------|------|---------------------------|
| `chr20.tiny.100snps.vcf.gz` | 100 | 3.4 KB | ~1-2 minutes |
| `chr20.mini.500snps.vcf.gz` | 500 | 15 KB | ~2-3 minutes |
| `chr20.small.1000snps.vcf.gz` | 1,000 | 29 KB | ~3-4 minutes |
| `chr20.R50.merged.1.330k.recode.small.vcf.gz` | 7,824 | 231 KB | ~6-7 minutes |

## Details

- **Chromosome**: 20
- **Build**: hg19
- **Format**: VCF (gzipped)
- **Samples**: 51
- **Data type**: Phased genotypes

## Usage

### For Quick Development Testing
Use `chr20.tiny.100snps.vcf.gz` (100 variants) for:
- Testing job submission workflow
- Verifying API integration
- Quick iteration during development
- Estimated time: 1-2 minutes

### For Integration Testing
Use `chr20.mini.500snps.vcf.gz` (500 variants) for:
- Testing complete job lifecycle
- Verifying results download
- Integration tests
- Estimated time: 2-3 minutes

### For QA Testing
Use `chr20.small.1000snps.vcf.gz` (1,000 variants) for:
- Quality assurance
- Performance testing
- User acceptance testing
- Estimated time: 3-4 minutes

### For Production Simulation
Use `chr20.R50.merged.1.330k.recode.small.vcf.gz` (7,824 variants) for:
- Realistic imputation workflow
- End-to-end testing
- Performance benchmarking
- Estimated time: 6-7 minutes

## Example Job Submission

```bash
# Quick test with tiny file
curl -X POST http://localhost:8000/api/jobs/ \
  -H "Authorization: Bearer $TOKEN" \
  -F "name=Quick Test" \
  -F "service_id=1" \
  -F "reference_panel_id=37" \
  -F "input_format=vcf" \
  -F "build=hg19" \
  -F "phasing=true" \
  -F "input_file=@/path/to/chr20.tiny.100snps.vcf.gz"
```

## Notes

- All files are derived from the original `chr20.R50.merged.1.330k.recode.small.vcf.gz`
- Processing times are estimates based on H3Africa Imputation Server performance
- Actual times may vary depending on server load and network conditions
- Files contain the first N variants from chromosome 20

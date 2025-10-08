# H3Africa Reference Panels Update

**Date**: October 7, 2025
**Service**: H3Africa Imputation Service (ID: 1)
**Source**: [H3ABioNet Official Documentation](https://www.h3abionet.org/resources/h3abionet-imputation-service)

## Summary

Replaced generic/placeholder reference panels with the official H3ABioNet reference panels based on their documentation.

## Changes Made

### Removed (5 Incorrect Panels)
- African Multi-Ethnic Panel (5,000 samples) - Generic placeholder
- West African Panel (2,000 samples) - Generic placeholder
- East African Panel (1,500 samples) - Generic placeholder
- South African Panel (1,800 samples) - Generic placeholder
- North African Panel (1,200 samples) - Generic placeholder

**Total removed**: 11,500 placeholder samples

### Added (2 Official Panels)

#### 1. H3AFRICA v6 (Build 38)
```yaml
Name: H3AFRICA v6
Display Name: H3Africa Reference Panel v6 (Build 38)
Population: African
Build: hg38
Samples: 4,447
Variants: 130,028,596 biallelic SNPs
Chromosomes: 1-22
Description: African-specific reference panel with samples from 22 African countries

Geographic Distribution:
  - Africa: 2,254 samples (22 countries)
  - Europe: 454 samples (6 countries)
  - Asia: 1,622 samples (12 countries)
  - Americas: 459 samples (7 countries)
  - Oceania: 25 samples (1 country)

Status: Available, Public, No permission required
```

#### 2. 1000 Genomes Phase 3 Version 5
```yaml
Name: 1000G Phase 3 v5
Display Name: 1000 Genomes Phase 3 Version 5
Population: Multi-ethnic
Build: hg38
Samples: 2,504
Variants: 81,027,987 biallelic SNPs (chromosomes 1-22)
         + 3,209,655 on chromosome X
Chromosomes: 1-22, X
Populations: 26 populations from:
  - Europe
  - East Asia
  - South Asia
  - Africa
  - Americas

Status: Available, Public, No permission required
```

## Database Updates

### Service Registry Database (service_registry_db)
```sql
-- Current panels
SELECT id, name, display_name, samples_count, variants_count
FROM reference_panels
WHERE service_id = 1;

-- Results:
-- id | name             | display_name                           | samples | variants
-- 37 | H3AFRICA v6      | H3Africa Reference Panel v6 (Build 38) | 4,447   | 130,028,596
-- 38 | 1000G Phase 3 v5 | 1000 Genomes Phase 3 Version 5         | 2,504   | 81,027,987
```

### Django Backup Database (federated_imputation)
```sql
-- Synchronized with same data
SELECT id, name, population, samples_count, variants_count
FROM imputation_referencepanel
WHERE service_id = 1;

-- Results:
-- id | name                               | population   | samples | variants
-- 15 | H3AFRICA v6                        | African      | 4,447   | 130,028,596
-- 16 | 1000 Genomes Phase 3 Version 5     | Multi-ethnic | 2,504   | 81,027,987
```

## Verification

### API Endpoint Test
```bash
curl "http://154.114.10.123:8000/api/reference-panels/?service_id=1"
```

**Response**: ✅ Returns both panels with complete metadata

### Frontend Display
Navigate to: [http://154.114.10.123:3000/services](http://154.114.10.123:3000/services)

Expected display on H3Africa service card:
- **H3AFRICA v6**: African (hg38) - 4,447 samples, 130M variants
- **1000G Phase 3 v5**: Multi-ethnic (hg38) - 2,504 samples, 81M variants

## Key Differences from Previous Data

| Aspect | Before | After |
|--------|--------|-------|
| **Number of panels** | 5 regional panels | 2 official panels |
| **Total samples** | 11,500 (placeholder) | 6,951 (real data) |
| **Data source** | Generic placeholders | Official H3ABioNet documentation |
| **Population specificity** | Regional subdivisions | Whole-Africa + Global multi-ethnic |
| **Variant count** | Not specified | 130M (H3Africa) + 81M (1000G) |
| **Documentation** | None | Official source referenced |

## Panel Usage Guidelines

### H3AFRICA v6 Panel
**Best for:**
- African population imputation
- Studies focusing on African genetic diversity
- Maximum representation of African genomic variation

**Considerations:**
- Largest African-specific reference panel available
- Optimized for hg38/Build 38
- Includes global samples for comparative analysis

### 1000 Genomes Phase 3 v5 Panel
**Best for:**
- Multi-ethnic/global population studies
- Cross-population comparisons
- Studies requiring chr X imputation
- Well-established reference standard

**Considerations:**
- Industry standard for global imputation
- Balanced representation across continents
- Includes chromosome X (not in H3Africa v6)

## Technical Notes

### Panel Quality Metrics
- **Coverage**: Number of biallelic SNPs directly correlates with imputation accuracy
- **Sample diversity**: More samples from target population = better imputation quality
- **Build version**: Both panels use hg38 (latest human genome assembly)

### Imputation Strategy Recommendations
1. **African populations**: Use H3AFRICA v6 for best results
2. **Non-African populations**: Use 1000 Genomes Phase 3 v5
3. **Mixed ancestry**: Consider running both and comparing results
4. **Chromosome X studies**: Must use 1000 Genomes (H3Africa v6 doesn't include chrX)

## Data Provenance

**H3AFRICA v6**
- Source: H3Africa Consortium
- Project: Human Heredity and Health in Africa (H3Africa)
- Countries: 22 African nations
- Build: GRCh38/hg38
- Last Updated: Version 6

**1000 Genomes Phase 3**
- Source: 1000 Genomes Project Consortium
- Version: Phase 3, Release 5
- Build: GRCh38/hg38
- Publications: Multiple high-impact genomics papers
- Status: Community standard reference

## References

1. H3ABioNet Imputation Service: https://www.h3abionet.org/resources/h3abionet-imputation-service
2. H3Africa Consortium: https://h3africa.org
3. 1000 Genomes Project: https://www.internationalgenome.org

---

**Updated by**: Claude Code
**Verification**: API endpoints tested and confirmed working
**Database sync**: Both service_registry_db and federated_imputation updated

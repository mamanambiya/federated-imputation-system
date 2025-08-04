#!/bin/bash
set -e

echo "🔍 Database Data Monitoring"
echo "=========================="

# Check if services exist
SERVICES_COUNT=$(sudo docker-compose exec -T db psql -U postgres -d federated_imputation -t -c "SELECT count(*) FROM imputation_imputationservice;" | xargs)
PANELS_COUNT=$(sudo docker-compose exec -T db psql -U postgres -d federated_imputation -t -c "SELECT count(*) FROM imputation_referencepanel;" | xargs)

echo "📊 Current data status:"
echo "  - Services: $SERVICES_COUNT"
echo "  - Reference Panels: $PANELS_COUNT"

# Define minimum expected counts
MIN_SERVICES=4
MIN_PANELS=10

# Check if data is missing
if [ "$SERVICES_COUNT" -lt "$MIN_SERVICES" ] || [ "$PANELS_COUNT" -lt "$MIN_PANELS" ]; then
    echo "⚠️  DATA LOSS DETECTED!"
    echo "   Expected: ≥$MIN_SERVICES services, ≥$MIN_PANELS panels"
    echo "   Found: $SERVICES_COUNT services, $PANELS_COUNT panels"
    
    # Find the latest backup with services
    LATEST_BACKUP=$(ls -t ./backups/federated_imputation_complete_with_inserts_*.sql | head -1)
    
    if [ -n "$LATEST_BACKUP" ] && [ -f "$LATEST_BACKUP" ]; then
        echo "🔄 Auto-restoring from latest backup: $LATEST_BACKUP"
        
        # Auto-restore data
        echo "🛠️  Recreating services data..."
        sudo docker-compose exec -T web python manage.py create_initial_data
        sudo docker-compose exec -T web python manage.py setup_example_services
        
        # Verify restoration
        NEW_SERVICES_COUNT=$(sudo docker-compose exec -T db psql -U postgres -d federated_imputation -t -c "SELECT count(*) FROM imputation_imputationservice;" | xargs)
        NEW_PANELS_COUNT=$(sudo docker-compose exec -T db psql -U postgres -d federated_imputation -t -c "SELECT count(*) FROM imputation_referencepanel;" | xargs)
        
        echo "📊 After restoration:"
        echo "  - Services: $NEW_SERVICES_COUNT"
        echo "  - Reference Panels: $NEW_PANELS_COUNT"
        
        if [ "$NEW_SERVICES_COUNT" -ge "$MIN_SERVICES" ] && [ "$NEW_PANELS_COUNT" -ge "$MIN_PANELS" ]; then
            echo "✅ Data successfully restored!"
            
            # Create new backup
            TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            sudo docker-compose exec db pg_dump -U postgres --inserts federated_imputation > "./backups/federated_imputation_auto_restored_$TIMESTAMP.sql"
            echo "💾 New backup created: federated_imputation_auto_restored_$TIMESTAMP.sql"
        else
            echo "❌ Restoration failed - manual intervention required"
            exit 1
        fi
    else
        echo "❌ No backup found - manual restoration required"
        echo "💡 Run: sudo docker-compose exec web python manage.py create_initial_data"
        echo "💡 Run: sudo docker-compose exec web python manage.py setup_example_services"
        exit 1
    fi
else
    echo "✅ Data integrity OK"
fi

# Check API availability
echo ""
echo "🌐 Testing API endpoints..."

# Test services API
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/services/ || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Services API responding (HTTP $HTTP_CODE)"
else
    echo "❌ Services API error (HTTP $HTTP_CODE)"
fi

# Test frontend
FRONTEND_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ || echo "000")
if [ "$FRONTEND_CODE" = "200" ]; then
    echo "✅ Frontend responding (HTTP $FRONTEND_CODE)"
else
    echo "❌ Frontend error (HTTP $FRONTEND_CODE)"
fi

echo ""
echo "🕒 Monitoring completed at $(date)"
echo "================================"
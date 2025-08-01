# Service Selection Modal Implementation

## Overview
The service selection has been redesigned from checkboxes to an interactive modal dialog with service cards, providing a much better user experience.

## Key Features

### 1. **Add Service Button**
- Instead of checkboxes, users now see an "Add Service" button
- Shows count of selected services when any are added
- Clean interface without clutter

### 2. **Modal Dialog with Service Cards**
Each service is displayed as an interactive card showing:
- Service icon (different for H3Africa vs Michigan)
- Service name prominently displayed
- Service description
- Number of available reference panels
- Maximum file size supported
- Hover effects and selection state

### 3. **Three-Step Selection Process**
1. **Select Service**: Click on a service card to select it
2. **Choose Reference Panel**: Dropdown appears with panel details:
   - Panel name
   - Population information
   - Build version (e.g., hg38)
   - Number of samples
3. **Accept Terms**: Each service has its own terms & conditions that must be accepted

### 4. **Selected Services List**
- Shows all selected services with their panels
- Delete button to remove services
- Visual confirmation of accepted terms
- Clean list interface with borders

## User Flow

1. User clicks "Add Service" button
2. Modal opens showing available services as cards
3. User clicks on a service card to select it
4. Reference panel dropdown appears below
5. User selects a reference panel
6. Terms & conditions section appears
7. User accepts terms by checking the checkbox
8. User clicks "Add Service" to confirm
9. Service is added to the selected services list
10. User can add more services or proceed to next step

## Technical Implementation

### Data Structure
```typescript
interface SelectedService {
  serviceId: string;
  serviceName: string;
  panelId: string;
  panelName: string;
  termsAccepted: boolean;
}
```

### State Management
- Modal open/close state
- Selected service in modal
- Selected panel in modal
- Terms acceptance state
- List of selected services

### UI Components
- Material-UI Dialog for modal
- Card components for services
- Select dropdown for panels
- Checkbox for terms
- List with delete actions

## Benefits

1. **Cleaner Interface**: No cluttered checkboxes, just a simple button
2. **Better Organization**: Services and panels selected together
3. **Clear Terms**: Each service's terms presented clearly
4. **Visual Feedback**: Cards provide hover states and selection feedback
5. **Easy Management**: Simple to add/remove services
6. **Scalable**: Works well with many services without overwhelming the UI

## Screenshots (Conceptual)

### Main View
```
┌─────────────────────────────────────┐
│ Select Imputation Services          │
│ Add one or more imputation services │
│                                     │
│ [ℹ️ No services selected yet...]    │
│                                     │
│ [➕ Add Service]                    │
└─────────────────────────────────────┘
```

### Modal View
```
┌─────────────────────────────────────┐
│ Add Imputation Service              │
├─────────────────────────────────────┤
│ Select Service                      │
│ ┌─────────┐ ┌─────────┐            │
│ │H3Africa │ │Michigan │            │
│ │Service  │ │Service  │            │
│ │[5 panels]│ │[3 panels]│          │
│ └─────────┘ └─────────┘            │
│                                     │
│ Select Reference Panel              │
│ [Dropdown: Choose panel...]         │
│                                     │
│ Terms & Conditions                  │
│ [□ I accept the terms]              │
│                                     │
│ [Cancel] [Add Service]              │
└─────────────────────────────────────┘
```

### Selected Services
```
┌─────────────────────────────────────┐
│ Selected Services (2)               │
│ ┌─────────────────────────────[🗑️]─┐│
│ │ H3Africa Service                 ││
│ │ Panel: African Panel             ││
│ │ ✓ Terms accepted                 ││
│ └───────────────────────────────────┘│
│ ┌─────────────────────────────[🗑️]─┐│
│ │ Michigan Service                 ││
│ │ Panel: HRC Panel                 ││
│ │ ✓ Terms accepted                 ││
│ └───────────────────────────────────┘│
└─────────────────────────────────────┘
```

This implementation provides a much more intuitive and visually appealing way to select imputation services while ensuring users understand and accept the terms for each service they use. 
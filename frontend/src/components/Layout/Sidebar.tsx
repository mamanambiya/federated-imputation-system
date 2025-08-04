import React from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import {
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Toolbar,
  Divider,
} from '@mui/material';
import {
  Dashboard,
  CloudUpload,
  Assignment,
  Add,
  Storage,
  DownloadDone,
  AdminPanelSettings,
} from '@mui/icons-material';

const drawerWidth = 240;

interface NavigationItem {
  text: string;
  icon: React.ReactElement;
  path: string;
  divider?: boolean;
}

interface SidebarProps {
  open: boolean;
}

const navigationItems: NavigationItem[] = [
  {
    text: 'Dashboard',
    icon: <Dashboard />,
    path: '/',
  },
  {
    text: 'Services',
    icon: <CloudUpload />,
    path: '/services',
  },
  {
    text: 'Jobs',
    icon: <Assignment />,
    path: '/jobs',
  },
  {
    text: 'New Job',
    icon: <Add />,
    path: '/jobs/new',
    divider: true,
  },
  {
    text: 'Results',
    icon: <DownloadDone />,
    path: '/results',
    divider: true,
  },
  {
    text: 'User Management',
    icon: <AdminPanelSettings />,
    path: '/user-management',
  },
];

const Sidebar: React.FC<SidebarProps> = ({ open }) => {
  const location = useLocation();
  const navigate = useNavigate();

  const handleNavigation = (path: string) => {
    navigate(path);
  };

  const isActivePath = (path: string) => {
    if (path === '/') {
      return location.pathname === '/';
    }
    return location.pathname.startsWith(path);
  };

  return (
    <Drawer
      variant="persistent"
      anchor="left"
      open={open}
      sx={{
        width: open ? drawerWidth : 0,
        flexShrink: 0,
        '& .MuiDrawer-paper': {
          width: drawerWidth,
          boxSizing: 'border-box',
          backgroundColor: 'background.paper',
          borderRight: '1px solid',
          borderColor: 'divider',
          transition: 'width 0.3s',
        },
      }}
    >
      <Toolbar />
      <List>
        {navigationItems.map((item) => (
          <React.Fragment key={item.text}>
            <ListItem disablePadding>
              <ListItemButton
                onClick={() => handleNavigation(item.path)}
                selected={isActivePath(item.path)}
                sx={{
                  '&.Mui-selected': {
                    backgroundColor: 'primary.main',
                    color: 'primary.contrastText',
                    '&:hover': {
                      backgroundColor: 'primary.dark',
                    },
                    '& .MuiListItemIcon-root': {
                      color: 'primary.contrastText',
                    },
                  },
                  '&:hover': {
                    backgroundColor: 'action.hover',
                  },
                }}
              >
                <ListItemIcon
                  sx={{
                    color: isActivePath(item.path) ? 'inherit' : 'text.primary',
                  }}
                >
                  {item.icon}
                </ListItemIcon>
                <ListItemText 
                  primary={item.text}
                  sx={{
                    '& .MuiListItemText-primary': {
                      fontWeight: isActivePath(item.path) ? 600 : 400,
                    },
                  }}
                />
              </ListItemButton>
            </ListItem>
            {item.divider && <Divider sx={{ my: 1 }} />}
          </React.Fragment>
        ))}
      </List>
    </Drawer>
  );
};

export default Sidebar; 
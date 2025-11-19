import {
  IconCalendar,
  IconChevronDown,
  IconPackage,
  IconSquareCheck,
  IconUsers,
} from '@tabler/icons-react';
import { Button, Menu, Text, Title, useMantineTheme } from '@mantine/core';
import { Link } from 'react-router';

export function AddMenu() {
  const theme = useMantineTheme();
  return (
    <Menu
      transitionProps={{ transition: 'pop-top-right' }}
      position="top-end"
      width={220}
      withinPortal
      radius="md"
    >
      <Menu.Target>
        <Button rightSection={<IconChevronDown size={18} stroke={1.5} />} pr={12} radius="xl">
         <Text size='10px' visibleFrom='xs'> Nouveau</Text>
         <Text size='10px' hiddenFrom='xs'> +</Text>
        </Button>
      </Menu.Target>
      <Menu.Dropdown>
        <Menu.Item
          leftSection={<IconCalendar size={16} color={theme.colors.violet[6]} stroke={1.5} />}
          
        >
         <Link to="/new-event">
          évènement
         </Link>
        </Menu.Item>
        <Menu.Item
          leftSection={<IconPackage size={16} color={theme.colors.blue[6]} stroke={1.5} />}
         
        >
          Type d'évènement
        </Menu.Item>
        <Menu.Item
          leftSection={<IconSquareCheck size={16} color={theme.colors.pink[6]} stroke={1.5} />}
          
        >
          Type de place
        </Menu.Item>
        {/* <Menu.Item
          leftSection={<IconUsers size={16} color={theme.colors.cyan[6]} stroke={1.5} />}
          
        >
          Team
        </Menu.Item> */}
      </Menu.Dropdown>
    </Menu>
  );
}
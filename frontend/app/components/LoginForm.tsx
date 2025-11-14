import {
  Anchor,
  Button,
  Checkbox,
  Container,
  Group,
  Paper,
  PasswordInput,
  Text,
  TextInput,
  Title,
} from '@mantine/core';
import classes from '../styles/AuthenticationTitle.module.css';
import { Form } from 'react-router';

export function LoginForm() {
  return (
    <Container size={420} my={40} pt={100}>
      <Title ta="center" className={classes.title}>
        Bienvenue à vous !!
      </Title>

      <Text className={classes.subtitle}>
        Connectez-vous pour gérer vos événements ainsi que les réservations..;;
      </Text>
    <Form method='POST'>

      <Paper withBorder shadow="sm" p={22} mt={30} radius="md">
        <TextInput label="Nom d'utilisateur" name='username' placeholder="Votre nom d'utilisateur" required radius="md" />
        <PasswordInput label="Mot de passe" name='password' placeholder="votre mot de passe" required mt="md" radius="md" />
        {/* <Group justify="space-between" mt="lg">
          <Checkbox label="Remember me" />
          <Anchor component="button" size="sm">
            Forgot password?
          </Anchor>
        </Group> */}
        <Button fullWidth mt="xl" radius="md" color='rgb(240, 9, 9)' type='submit'>
          Connexion
        </Button>
      </Paper>
    </Form>
    </Container>
  );
}
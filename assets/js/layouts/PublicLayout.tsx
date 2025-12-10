import { AppShell, Container, Group, Text, Button } from '@mantine/core'
import { Link } from '@inertiajs/react'
import type { PropsWithChildren } from 'react'
import { useTranslation } from 'react-i18next'

import type { SharedAppProps } from '@/types/app'

type Props = PropsWithChildren<{ app: SharedAppProps['app']; auth: SharedAppProps['auth'] }>

export const PublicLayout = ({ children, app, auth }: Props) => {
  const { t } = useTranslation('default')

  return (
    <AppShell
      header={{ height: 64 }}
      padding="md"
      styles={{
        main: {
          backgroundColor: 'var(--mantine-color-gray-0)',
          minHeight: '100vh'
        }
      }}
    >
      <AppShell.Header>
        <Container size="lg" h="100%">
          <Group h="100%" justify="space-between">
            <Link href="/" className="font-semibold text-lg tracking-wide">
              Medic
            </Link>
            <Group gap="xs">
              <Button component="a" href="/search" variant="subtle" size="sm">
                {t('nav.search', 'Search')}
              </Button>
              {auth.authenticated ? (
                <Button component="a" href="/dashboard" size="sm">
                  {t('nav.dashboard', 'Dashboard')}
                </Button>
              ) : (
                <Button component="a" href="/login" size="sm">
                  {t('nav.login', 'Sign in')}
                </Button>
              )}
            </Group>
          </Group>
        </Container>
      </AppShell.Header>
      <AppShell.Main>
        <Container size="lg" py="xl">
          <Text size="xs" c="dimmed" mb="sm">
            {app.locale.toUpperCase()} · {app.current_scope}
          </Text>
          {children}
        </Container>
      </AppShell.Main>
    </AppShell>
  )
}

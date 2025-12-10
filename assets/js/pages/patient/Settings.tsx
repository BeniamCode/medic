import { Button, Card, Stack, Text, TextInput, Title } from '@mantine/core'
import { useTranslation } from 'react-i18next'

import { PublicLayout } from '@/layouts/PublicLayout'
import type { AppPageProps } from '@/types/app'

type PageProps = AppPageProps<{
  profile: {
    email: string
    role: string
    confirmed_at: string | null
  }
}>

const SettingsPage = ({ app, auth, profile }: PageProps) => {
  const { t } = useTranslation('default')

  return (
    <PublicLayout app={app} auth={auth}>
      <Stack gap="lg" maw={600} mx="auto">
        <div>
          <Title order={2}>{t('settings.title', 'Account settings')}</Title>
          <Text c="dimmed">{t('settings.subtitle', 'Manage your profile and preferences')}</Text>
        </div>

        <Card withBorder padding="lg" radius="lg">
          <Stack gap="md">
            <Text fw={600}>{t('settings.profile.heading', 'Profile')}</Text>
            <TextInput label={t('settings.profile.email', 'Email')} value={profile.email} disabled />
            <TextInput
              label={t('settings.profile.role', 'Role')}
              value={profile.role}
              disabled
            />
            <Button disabled>{t('settings.profile.update', 'Update profile')}</Button>
          </Stack>
        </Card>

        <Card withBorder padding="lg" radius="lg">
          <Stack gap="md">
            <Text fw={600}>{t('settings.security.heading', 'Security')}</Text>
            <Button variant="light" disabled>
              {t('settings.security.change_password', 'Change password (coming soon)')}
            </Button>
          </Stack>
        </Card>
      </Stack>
    </PublicLayout>
  )
}

export default SettingsPage

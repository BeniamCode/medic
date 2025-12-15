import { Button as DesktopButton, Card as DesktopCard, Typography, Space, Row, Col } from 'antd'
import { useTranslation } from 'react-i18next'
import type { AppPageProps } from '@/types/app'
import { useIsMobile } from '@/lib/device'

// Mobile imports
import { List, Card as MobileCard, Button as MobileButton } from 'antd-mobile'
import { SetOutline, LockOutline } from 'antd-mobile-icons'

const { Title, Text } = Typography

type PageProps = AppPageProps<{
  profile: {
    email: string
    role: string
    confirmed_at: string | null
  }
}>

// =============================================================================
// MOBILE SETTINGS
// =============================================================================

function MobileSettingsPage({ profile }: { profile: PageProps['profile'] }) {
  const { t } = useTranslation('default')

  return (
    <div style={{ padding: 16, paddingBottom: 80 }}>
      <div style={{ marginBottom: 24 }}>
        <h2 style={{ fontSize: 22, fontWeight: 700, margin: '0 0 4px' }}>{t('settings.title', 'Account settings')}</h2>
        <p style={{ color: '#666', margin: 0, fontSize: 14 }}>{t('settings.subtitle', 'Manage your profile and preferences')}</p>
      </div>

      <MobileCard title="Profile" style={{ borderRadius: 12, marginBottom: 16 }}>
        <List>
          <List.Item extra={profile.email}>
            {t('settings.profile.email', 'Email')}
          </List.Item>
          <List.Item extra={profile.role}>
            {t('settings.profile.role', 'Role')}
          </List.Item>
        </List>
        <MobileButton
          block
          disabled
          style={{ marginTop: 12, '--border-radius': '8px' }}
        >
          {t('settings.profile.update', 'Update profile')}
        </MobileButton>
      </MobileCard>

      <MobileCard title="Security" style={{ borderRadius: 12 }}>
        <MobileButton
          block
          disabled
          fill="outline"
          style={{ '--border-radius': '8px' }}
        >
          {t('settings.security.change_password', 'Change password (coming soon)')}
        </MobileButton>
      </MobileCard>
    </div>
  )
}

// =============================================================================
// DESKTOP SETTINGS
// =============================================================================

function DesktopSettingsPage({ profile }: { profile: PageProps['profile'] }) {
  const { t } = useTranslation('default')

  return (
    <div style={{ maxWidth: 600, margin: '0 auto' }}>
      <div style={{ marginBottom: 24 }}>
        <Title level={2}>{t('settings.title', 'Account settings')}</Title>
        <Text type="secondary">{t('settings.subtitle', 'Manage your profile and preferences')}</Text>
      </div>

      <Space direction="vertical" size="large" style={{ width: '100%' }}>
        <DesktopCard bordered style={{ borderRadius: 12 }}>
          <Space direction="vertical" size="middle" style={{ width: '100%' }}>
            <Text strong>{t('settings.profile.heading', 'Profile')}</Text>
            <Row gutter={16}>
              <Col span={12}>
                <Text type="secondary" style={{ display: 'block', marginBottom: 4 }}>{t('settings.profile.email', 'Email')}</Text>
                <Text>{profile.email}</Text>
              </Col>
              <Col span={12}>
                <Text type="secondary" style={{ display: 'block', marginBottom: 4 }}>{t('settings.profile.role', 'Role')}</Text>
                <Text>{profile.role}</Text>
              </Col>
            </Row>
            <DesktopButton disabled>{t('settings.profile.update', 'Update profile')}</DesktopButton>
          </Space>
        </DesktopCard>

        <DesktopCard bordered style={{ borderRadius: 12 }}>
          <Space direction="vertical" size="middle" style={{ width: '100%' }}>
            <Text strong>{t('settings.security.heading', 'Security')}</Text>
            <DesktopButton disabled>
              {t('settings.security.change_password', 'Change password (coming soon)')}
            </DesktopButton>
          </Space>
        </DesktopCard>
      </Space>
    </div>
  )
}

// =============================================================================
// MAIN COMPONENT
// =============================================================================

const SettingsPage = ({ app, auth, profile }: PageProps) => {
  const isMobile = useIsMobile()

  if (isMobile) {
    return <MobileSettingsPage profile={profile} />
  }

  return <DesktopSettingsPage profile={profile} />
}

export default SettingsPage

import { Layout, Button, Typography, theme, Flex } from 'antd'
import { Link } from '@inertiajs/react'
import type { PropsWithChildren } from 'react'
import { useTranslation } from 'react-i18next'

import type { SharedAppProps } from '@/types/app'

const { Header, Content } = Layout
const { Text } = Typography

type Props = PropsWithChildren<{ app: SharedAppProps['app']; auth: SharedAppProps['auth'] }>

export const PublicLayout = ({ children, app, auth }: Props) => {
  const { t } = useTranslation('default')
  const {
    token: { colorBgContainer },
  } = theme.useToken()

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Header style={{
        background: colorBgContainer,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '0 24px',
        height: 64,
        borderBottom: '1px solid #f0f0f0'
      }}>
        <Link href="/" className="font-semibold text-lg tracking-wide text-black hover:text-teal-600">
          Medic
        </Link>
        <Flex gap="small">
          <Link href="/search">
            <Button type="text">
              {t('nav.search', 'Search')}
            </Button>
          </Link>
          {auth.authenticated ? (
            <Link href="/dashboard">
              <Button type="primary">
                {t('nav.dashboard', 'Dashboard')}
              </Button>
            </Link>
          ) : (
            <Link href="/login">
              <Button type="primary">
                {t('nav.login', 'Sign in')}
              </Button>
            </Link>
          )}
        </Flex>
      </Header>
      <Content style={{ padding: '24px 0', background: '#f5f5f5' }}>
        <div style={{ maxWidth: 1200, margin: '0 auto', padding: '0 24px' }}>
          <Text type="secondary" style={{ fontSize: 12, marginBottom: 16, display: 'block' }}>
            {app.locale.toUpperCase()} · {app.currentScope}
          </Text>
          {children}
        </div>
      </Content>
    </Layout>
  )
}

import { Dropdown, Button, MenuProps, theme } from 'antd'
import { GlobalOutlined } from '@ant-design/icons'
import { router, usePage } from '@inertiajs/react'
import { useTranslation } from 'react-i18next'
import { SharedAppProps } from '@/types/app'

const LOCALE_LABELS: Record<string, string> = {
    en: 'EN',
    el: 'EL'
}

export const LanguageSwitcher = () => {
    const { i18n } = useTranslation()
    const { locale } = usePage<SharedAppProps>().props.i18n
    const { token } = theme.useToken()

    const currentLocale = locale || i18n.language || 'en'

    const handleMenuClick: MenuProps['onClick'] = (e) => {
        if (e.key === currentLocale) return

        // Reload page with new locale param to persist in session
        const url = new URL(window.location.href)
        url.searchParams.set('locale', e.key)

        router.visit(url.toString(), {
            preserveScroll: true,
            preserveState: false, // Force full reload to fetch new translations
        })
    }

    const items: MenuProps['items'] = [
        {
            key: 'en',
            label: 'English (EN)',
        },
        {
            key: 'el',
            label: 'Ελληνικά (EL)',
        }
    ]

    return (
        <Dropdown menu={{ items, onClick: handleMenuClick, selectedKeys: [currentLocale] }} placement="bottomRight" trigger={['click']}>
            <Button
                type="dashed"
                size="small"
                style={{
                    borderColor: token.colorBorder,
                    color: token.colorTextSecondary,
                    opacity: 0.8,
                    fontSize: 12,
                    display: 'flex',
                    alignItems: 'center',
                    gap: 4
                }}
            >
                <GlobalOutlined style={{ fontSize: 12 }} />
                {LOCALE_LABELS[currentLocale] || currentLocale.toUpperCase()}
            </Button>
        </Dropdown>
    )
}

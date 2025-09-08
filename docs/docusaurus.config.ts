import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: 'Roadtrip Planner Documentation',
  tagline: 'A Rails 8 application for planning and managing road trips',
  favicon: 'img/favicon.svg',

  // Future flags, see https://docusaurus.io/docs/api/docusaurus-config#future
  future: {
    v4: true, // Improve compatibility with the upcoming Docusaurus v4
  },

  // Set the production url of your site here
  url: 'https://mnaray.github.io',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/roadtrip_planner/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'mnaray', // Usually your GitHub org/user name.
  projectName: 'roadtrip_planner', // Usually your repo name.

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/mnaray/roadtrip_planner/tree/main/docs/',
        },
        blog: false, // Disable blog functionality
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    // Custom social card for road trip planner
    image: 'img/roadtrip-social-card.svg',
    navbar: {
      title: 'Roadtrip Planner',
      logo: {
        alt: 'Roadtrip Planner Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Documentation',
        },
        {
          href: 'https://github.com/mnaray/roadtrip_planner',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Documentation',
          items: [
            {
              label: 'Getting Started',
              to: '/docs/intro',
            },
            {
              label: 'Architecture Overview',
              to: '/docs/architecture/overview',
            },
            {
              label: 'Technologies',
              to: '/docs/technologies',
            },
          ],
        },
        {
          title: 'Development',
          items: [
            {
              label: 'Contributing Guide',
              to: '/docs/contributing',
            },
            {
              label: 'Models Reference',
              to: '/docs/models/overview',
            },
            {
              label: 'Services Reference',
              to: '/docs/services/overview',
            },
          ],
        },
        {
          title: 'Community',
          items: [
            {
              label: 'GitHub Repository',
              href: 'https://github.com/mnaray/roadtrip_planner',
            },
            {
              label: 'Issues & Bugs',
              href: 'https://github.com/mnaray/roadtrip_planner/issues',
            },
            {
              label: 'Feature Requests',
              href: 'https://github.com/mnaray/roadtrip_planner/issues/new?template=feature_request.md',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Roadtrip Planner. Built with Rails 8 and Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;

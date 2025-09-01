import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

/**
 * Creating a sidebar enables you to:
 - create an ordered group of docs
 - render a sidebar for each doc of that group
 - provide next/previous navigation

 The sidebars can be generated from the filesystem, or explicitly defined here.

 Create as many sidebars as you want.
 */
const sidebars: SidebarsConfig = {
  // Documentation sidebar structure
  docsSidebar: [
    'intro',
    {
      type: 'category',
      label: 'Getting Started',
      items: [
        'contributing',
        'technologies',
        'development-setup',
      ],
    },
    {
      type: 'category',
      label: 'Architecture',
      items: [
        'architecture/overview',
        'architecture/conventions',
        'architecture/ci-cd',
      ],
    },
    {
      type: 'category',
      label: 'Models',
      items: [
        'models/overview',
        'models/user',
        'models/road-trip',
        'models/route',
      ],
    },
    {
      type: 'category',
      label: 'Services',
      items: [
        'services/overview',
        'services/route-distance-calculator',
        'services/route-gpx-exporter',
        'services/route-gpx-generator',
      ],
    },
    {
      type: 'category',
      label: 'Components',
      items: [
        'components/overview',
        'components/application-component',
        'components/layout-components',
        'components/form-components',
        'components/feature-components',
      ],
    },
    {
      type: 'category',
      label: 'Development',
      items: [
        'development/testing',
        'development/deployment',
      ],
    },
  ],
};

export default sidebars;

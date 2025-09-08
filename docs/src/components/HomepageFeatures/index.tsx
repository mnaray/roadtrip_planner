import type {ReactNode} from 'react';
import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

type FeatureItem = {
  title: string;
  Svg: React.ComponentType<React.ComponentProps<'svg'>>;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Modern Rails Architecture',
    Svg: require('@site/static/img/undraw_travel_mode.svg').default,
    description: (
      <>
        Built with Rails 8 and Ruby 3.4, featuring Phlex components, Tailwind CSS v4, 
        and a completely containerized development environment for consistent deployment.
      </>
    ),
  },
  {
    title: 'Plan Your Adventure',
    Svg: require('@site/static/img/undraw_journey_planning.svg').default,
    description: (
      <>
        Create detailed road trip plans with multiple routes, manage destinations and timing, 
        and track your journey progress with an intuitive, responsive interface.
      </>
    ),
  },
  {
    title: 'Hit the Road',
    Svg: require('@site/static/img/undraw_road_trip.svg').default,
    description: (
      <>
        Experience the freedom of the open road with comprehensive trip management, 
        real-time updates, and seamless collaboration features for unforgettable journeys.
      </>
    ),
  },
];

function Feature({title, Svg, description}: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <Svg className={styles.featureSvg} role="img" />
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}

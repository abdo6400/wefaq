export type AnnouncementStyle = 'info' | 'warning' | 'success';

export type SampleTopicKey =
  | 'communication'
  | 'dailyLife'
  | 'familyRelations'
  | 'finances'
  | 'coreValues';

export interface SiteFeatureCard {
  readonly icon: string;
  readonly title: string;
  readonly description: string;
}

export interface SiteStepItem {
  readonly title: string;
  readonly description: string;
}

export interface SiteFaqItem {
  readonly question: string;
  readonly answer: string;
}

export interface SiteSampleItem {
  readonly question: string;
  readonly clarification: string;
}

export interface SiteContentConfig {
  readonly meta: {
    readonly brandName: string;
    readonly pageTitle: string;
    readonly footerText: string;
  };
  readonly hero: {
    readonly primaryCtaLabel: string;
    readonly secondaryCtaLabel: string;
    readonly downloadCtaLabel: string;
    readonly trustPills: readonly string[];
    readonly mockupTitle: string;
    readonly mockupSubtitle: string;
    readonly mockupQuestion: string;
    readonly mockupClarify: string;
  };
  readonly sections: {
    readonly showFeatures: boolean;
    readonly featuresBadge: string;
    readonly featuresTitle: string;
    readonly featuresSubtitle: string;
    readonly showExplorer: boolean;
    readonly explorerBadge: string;
    readonly explorerTitle: string;
    readonly explorerSubtitle: string;
    readonly showActivities: boolean;
    readonly activitiesBadge: string;
    readonly activitiesTitle: string;
    readonly activitiesSubtitle: string;
    readonly showHowItWorks: boolean;
    readonly howItWorksBadge: string;
    readonly howItWorksTitle: string;
    readonly howItWorksSubtitle: string;
    readonly showContact: boolean;
    readonly contactBadge: string;
    readonly contactTitle: string;
    readonly contactSubtitle: string;
    readonly showFaq: boolean;
    readonly faqBadge: string;
    readonly faqTitle: string;
    readonly showBoundaries: boolean;
  };
  readonly featuresCards: readonly SiteFeatureCard[];
  readonly activitiesCards: readonly SiteFeatureCard[];
  readonly steps: readonly SiteStepItem[];
  readonly contactForm: {
    readonly reasons: readonly string[];
    readonly namePlaceholder: string;
    readonly notesPlaceholder: string;
    readonly previewHeading: string;
    readonly previewHint: string;
  };
  readonly faq: readonly SiteFaqItem[];
  readonly boundaries: {
    readonly whatIsTitle: string;
    readonly whatIsItems: readonly string[];
    readonly whatIsNotTitle: string;
    readonly whatIsNotItems: readonly string[];
  };
  readonly privacyPage: {
    readonly badge: string;
    readonly title: string;
    readonly subtitle: string;
  };
  readonly sampleQuestions: {
    readonly communication: readonly SiteSampleItem[];
    readonly dailyLife: readonly SiteSampleItem[];
    readonly familyRelations: readonly SiteSampleItem[];
    readonly finances: readonly SiteSampleItem[];
    readonly coreValues: readonly SiteSampleItem[];
  };
}

export interface AppConfigSnapshot {
  readonly schemaVersion: 1;
  readonly revision: number;
  readonly updatedAt: string;
  readonly contact: {
    readonly whatsappNumber: string;
    readonly whatsappDisplay: string;
    readonly email: string;
    readonly supportHours: string;
    readonly contactMessageTemplate: string;
    readonly telegramUrl: string;
    readonly telegramDisplay: string;
    readonly phoneDisplay: string;
    readonly websiteUrl: string;
  };
  readonly announcement: {
    readonly enabled: boolean;
    readonly title: string;
    readonly message: string;
    readonly style: AnnouncementStyle;
  };
  readonly appRelease: {
    readonly latestVersion: string;
    readonly minSupportedVersion: string;
    readonly releaseNotes: string;
    readonly downloadUrl: string;
  };
  readonly features: {
    readonly quickSparkEnabled: boolean;
    readonly activitiesEnabled: boolean;
    readonly discEnabled: boolean;
    readonly feedbackEnabled: boolean;
  };
  readonly branding: {
    readonly badgeText: string;
    readonly heroTitle: string;
    readonly heroSubtitle: string;
    readonly siteNotice: string;
  };
  readonly site: SiteContentConfig;
}

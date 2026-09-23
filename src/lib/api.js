// Thin facade over window.admin (the preload bridge).
export const admin = window.admin ?? {
  saveManualShadeReport: async () => {
    throw new Error('Open the desktop admin app to publish reports.');
  },
  // No-op fallback so the renderer can still mount in a plain browser tab during dev.
  confirmEntity: async () => ({}),
  upsertProduct: async () => ({}),
  updateProduct: async () => ({}),
  addShade: async () => ({}),
  linkMention: async () => ({}),
  saveShadeTwin: async () => ({}),
  updateCreator: async () => ({}),
  on: () => () => {},
};

class CloudPreset {
  final String name;
  final String defaultUrl;
  final String description;
  const CloudPreset(this.name, this.defaultUrl, this.description);
}

const cloudPresets = [
  CloudPreset('坚果云', 'https://dav.jianguoyun.com/dav/', '需在坚果云设置中开启第三方应用密码'),
  CloudPreset('Nextcloud', '', '请填写您的 Nextcloud 服务器地址'),
  CloudPreset('自定义', '', '任意 WebDAV 兼容服务'),
];
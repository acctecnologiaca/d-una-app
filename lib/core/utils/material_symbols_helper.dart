class MaterialSymbolsHelper {
  static String getSvgUrl(String name, [String style = 'outlined']) {
    // Styles: outlined, rounded, sharp
    // Folder pattern: symbols/web/<name>/materialsymbols<style>/<name>_24px.svg
    // Note: 'materialsymbols' prefix is required for the folder name in the repo
    final sanitizedName = name.toLowerCase().trim();
    final folderStyle = 'materialsymbols$style';

    return 'https://raw.githubusercontent.com/google/material-design-icons/master/symbols/web/$sanitizedName/$folderStyle/${sanitizedName}_24px.svg';
  }
}

git add .github/workflows/release.yml
git commit -m "Fix: Flutter version updated to 3.41.x"
git push origin main
# Eski tag'i silip yenisini oluşturun
git tag -d v1.1.1
git push origin :refs/tags/v1.1.1
git tag v1.1.1
git push origin v1.1.1
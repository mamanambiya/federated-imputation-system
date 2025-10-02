# Page snapshot

```yaml
- generic [ref=e1]:
  - generic [ref=e2]:
    - link "Skip to main content" [ref=e3] [cursor=pointer]:
      - /url: "#main-content"
    - generic [ref=e6]:
      - img "AfriGen-D" [ref=e8]
      - heading "Federated Genomic Imputation Platform" [level=1] [ref=e9]
      - heading "Sign in to your account" [level=6] [ref=e10]
      - generic [ref=e11]:
        - generic [ref=e12]:
          - generic [ref=e13]:
            - text: Username
            - generic [ref=e14]: "*"
          - generic [ref=e15]:
            - img [ref=e16]
            - textbox "Username" [active] [ref=e18]
            - group:
              - generic: Username *
        - generic [ref=e19]:
          - generic [ref=e20]:
            - text: Password
            - generic [ref=e21]: "*"
          - generic [ref=e22]:
            - img [ref=e23]
            - textbox "Password" [ref=e25]
            - group:
              - generic: Password *
        - button "Sign In" [ref=e26] [cursor=pointer]: Sign In
        - paragraph [ref=e29]: "Demo credentials: admin / admin123"
  - region "Notifications"
```
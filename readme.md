
## 構造

```
manifests/
├── bases
│   ├── argocd-appset
│   ├── workload1
│   │   ├── deployment
│   │   │   └── ...
│   │   └── service.yaml
│   ├── workload2
│   └── workload3
├── components
│   └── component1
│   └── component2
└── overlays
    ├── cluster1
    │   ├── .envrc
    │   ├── argocd
    │   │   └── argocd-appset
    │   ├── clusterwide
    │   │   └── XXXX
    │   ├── namespace1
    │   │   ├── workload1
    │   │   ├── workload1-<suffix>
    │   │   └── workload3
    │   └── namespace2
    └── .envrc-common
```

- manifests/bases/\<module\>
  - 原則 1 ワークロード 1 kustomization でまとめる
- manifests/overlays/\<cluster\>/\<namespace\>/\<module\>
  - デプロイ先の実体に合わせた構造。ArgoCD ApplicationSet とも相性が良い
  - bases 内の module を選んで配置するイメージ
  - ingress 等の複数 module 間で共用するリソースは適当なディレクトリを作成して階層を合わせる
    - overlays/cluster1/namespace1/ingress など
- manifests/components/\<module\>:
  - 共通のパッチ等を kustomize の Component として再利用できるように配置する

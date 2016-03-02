
#prepare:
#  salt.state:
#    - tgt: "E@mon.*|data.*|igw.*|client.*|mds.*"
#    - tgt_type: compound
#    - highstate: True
#
#after reboots:
#  salt.state:
#    - tgt: "E@mon.*|data.*|igw.*|client.*|mds.*"
#    - tgt_type: compound
#    - highstate: True
#    - require:
#      - salt: prepare

install:
  salt.state:
    - tgt: "admin.ceph"
    - sls: deploy

reweight:
  salt.state:
    - tgt: "mon1.ceph"
    - sls: deploy.reweight
    - require:
      - salt: install

rbd images:
  salt.state:
    - tgt: "mon1.ceph"
    - sls: deploy.configure
    - require:
      - salt: reweight

cephfs:
  salt.state:
    - tgt: "mon1.ceph"
    - sls: cephfs.pools
    - require:
      - salt: rbd images

iscsi import:
  salt.state:
    - tgt: "igw1.ceph"
    - sls: iscsi.import
    - require:
      - salt: cephfs

iscsi apply:
  salt.state:
    - tgt: "E@igw.*"
    - tgt_type: compound
    - sls: iscsi.lrbd
    - require:
      - salt: iscsi import

multipathd:
  salt.state:
    - tgt: "E@client.*"
    - tgt_type: compound
    - sls: initiator.multipathd
    - require:
      - salt: iscsi apply

iscsiadm:
  salt.state:
    - tgt: "E@client.*"
    - tgt_type: compound
    - sls: initiator.iscsiadm
    - require:
      - salt: multipathd

mds:
  salt.state:
    - tgt: "admin.ceph"
    - sls: cephfs
    - require:
      - salt: iscsiadm

mds clients:
  salt.state:
    - tgt: "E@client.*"
    - tgt_type: compound
    - sls: cephfs.client
    - require:
      - salt: mds

"""add_project_id_to_transfer

Revision ID: 551c1105aab8
Revises: a28d613ba812
Create Date: 2026-05-28 08:30:15.858972

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '551c1105aab8'
down_revision: Union[str, None] = 'a28d613ba812'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add project_id column as FK to transfers table
    op.add_column('transfers', sa.Column('project_id', sa.Integer(), nullable=True))
    op.create_foreign_key('fk_transfers_projects', 'transfers', 'projects', ['project_id'], ['id'])


def downgrade() -> None:
    op.drop_constraint('fk_transfers_projects', 'transfers', type_='foreignkey')
    op.drop_column('transfers', 'project_id')

"""add_color_icon_type_to_category

Revision ID: fb0969acb962
Revises: 54a181fe20f9
Create Date: 2026-05-22 18:45:54.264781

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'fb0969acb962'
down_revision: Union[str, None] = '54a181fe20f9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # The categories table was never created by a prior migration.
    # Create the full table here (matches the Category model).
    op.create_table(
        'categories',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(), nullable=False),
        sa.Column('color', sa.String(), server_default='#9E9E9E', nullable=False),
        sa.Column('icon', sa.String(), nullable=True),
        sa.Column('type', sa.String(), server_default='expense', nullable=False),
        sa.Column('is_active', sa.Boolean(), server_default='true', nullable=False),
        sa.Column('sort_order', sa.Integer(), server_default='0', nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('name'),
    )
    op.create_index(op.f('ix_categories_id'), 'categories', ['id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_categories_id'), table_name='categories')
    op.drop_table('categories')

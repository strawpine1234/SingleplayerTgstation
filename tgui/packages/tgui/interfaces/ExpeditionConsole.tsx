import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Mission = {
  id: string;
  kind: string;
  title: string;
  description: string;
  difficulty: number;
  rewards: { id: string; name: string; description: string }[];
  work_seconds: number;
  state: string;
  gps: string;
  coordinates: string | null;
  kills: number;
  targets: number;
  recovered: boolean;
};

type Data = {
  status: string;
  completed: number;
  cooldown: number;
  active: Mission | null;
  offers: Mission[];
};

export const ExpeditionConsole = () => {
  const { act, data } = useBackend<Data>();
  const { active, offers, status, completed, cooldown } = data;
  return (
    <Window width={650} height={720} title="Expedition Mission Console">
      <Window.Content scrollable>
        <NoticeBox>{status}</NoticeBox>
        <Section title={`Expedition Board — ${completed} completed`}>
          <Box>
            Travel using the mining shuttle or your usual mining transport.
            Bring a GPS and protection for the mining planet. Sites are deployed
            in Lavaland wilderness or the ice moon underground. All consoles
            share one active expedition. Rewards arrive beside the console.
          </Box>
          {cooldown > 0 && (
            <Box mt={1} color="average">
              Next departure in {cooldown} seconds.
            </Box>
          )}
        </Section>
        {active ? (
          <Section title={active.title}>
            <MissionDetails mission={active} />
            <LabeledList>
              <LabeledList.Item label="State">{active.state}</LabeledList.Item>
              <LabeledList.Item label="GPS signal">
                {active.gps}
              </LabeledList.Item>
              <LabeledList.Item label="Coordinates (X, Y, Z)">
                {active.coordinates || 'Beacon unavailable'}
              </LabeledList.Item>
              {active.targets > 0 && (
                <LabeledList.Item label="Assigned fauna eliminated">
                  {active.kills} / {active.targets}
                </LabeledList.Item>
              )}
            </LabeledList>
            {active.kind === 'salvage' && active.recovered && (
              <NoticeBox>
                Bring the flight recorder back and use it on this console.
              </NoticeBox>
            )}
            {active.state === 'failed' && (
              <NoticeBox danger>
                The objective or a required target was lost. Abandon this
                expedition to try another.
              </NoticeBox>
            )}
            {active.state === 'complete' && (
              <Section title="Choose one reward">
                <Stack vertical>
                  {active.rewards.map((reward) => (
                    <Stack.Item key={reward.id}>
                      <Button
                        fluid
                        icon="gift"
                        color="good"
                        onClick={() =>
                          act('claim', { id: active.id, reward: reward.id })
                        }
                      >
                        {reward.name}
                      </Button>
                      <Box mt={1} color="label">
                        {reward.description}
                      </Box>
                    </Stack.Item>
                  ))}
                </Stack>
              </Section>
            )}
            <Box mt={2}>
              <Button.Confirm
                color="bad"
                icon="ban"
                onClick={() => act('abandon', { id: active.id })}
              >
                Abandon Expedition
              </Button.Confirm>
              <Box mt={1} color="label">
                Abandonment removes the deployed site and its assigned fauna,
                then imposes a one-minute departure cooldown.
              </Box>
            </Box>
          </Section>
        ) : (
          offers.map((mission) => (
            <Section key={mission.id} title={mission.title}>
              <MissionDetails mission={mission} />
              <Button
                icon="rocket"
                disabled={cooldown > 0}
                onClick={() => act('accept', { id: mission.id })}
              >
                Accept Expedition
              </Button>
            </Section>
          ))
        )}
      </Window.Content>
    </Window>
  );
};

const MissionDetails = ({ mission }: { mission: Mission }) => (
  <Box mb={2}>
    <Box mb={1}>{mission.description}</Box>
    <Box color="average">
      Difficulty: {mission.difficulty}/3 · Field work: {mission.work_seconds}{' '}
      seconds
    </Box>
    <Box color="label">
      Reward choice: {mission.rewards.map((reward) => reward.name).join(', ')}.
    </Box>
  </Box>
);
